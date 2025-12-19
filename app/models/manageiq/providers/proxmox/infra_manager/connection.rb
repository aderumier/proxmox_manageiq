require "faraday"
require "faraday-cookie_jar"
require "json"
require "cgi"

module ManageIQ
  module Providers
    module Proxmox
      class InfraManager
        class Connection
          attr_reader :username, :password, :hostname, :port, :scheme

          def initialize(options = {})
            @username = options[:username]
            @password = options[:password]
            @hostname = options[:hostname]
            @port     = options[:port] || 8006
            @scheme   = options[:scheme] || "https"
          end

          def connect
            @connection ||= begin
              Faraday.new(:url => base_url) do |conn|
                conn.use :cookie_jar
                conn.request :url_encoded
                conn.adapter Faraday.default_adapter
                conn.ssl.verify = false # Proxmox often uses self-signed certificates
              end
            end
          end

          def verify
            # Authenticate and verify connection
            authenticate
            # Try to get cluster status to verify connection
            get("/api2/json/cluster/status")
            true
          end

          def authenticate
            # Don't use ensure_authenticated here - we're doing the authentication
            form_data = "username=#{CGI.escape(username)}&password=#{CGI.escape(password)}"
            response = connect.post("/api2/json/access/ticket", form_data) do |req|
              req.headers["Content-Type"] = "application/x-www-form-urlencoded"
            end

            if response.status == 200
              data = JSON.parse(response.body)
              @ticket = data["data"]["ticket"]
              @csrf_token = data["data"]["CSRFPreventionToken"]
              true
            else
              error_msg = begin
                JSON.parse(response.body)["errors"]&.first&.dig("message") || response.body
              rescue
                response.body
              end
              raise ManageIQ::Providers::Proxmox::InfraManager::AuthenticationError.new(
                "Authentication failed: #{error_msg}"
              )
            end
          end

          def get(path, params = {})
            ensure_authenticated
            response = connect.get(path, params) do |req|
              req.headers["Cookie"] = "PVEAuthCookie=#{@ticket}"
            end
            handle_response(response)
          end

          def post(path, body = {})
            ensure_authenticated
            # Proxmox API expects form-urlencoded data
            form_data = body.map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join("&")
            response = connect.post(path, form_data) do |req|
              req.headers["Cookie"] = "PVEAuthCookie=#{@ticket}"
              req.headers["CSRFPreventionToken"] = @csrf_token if @csrf_token
              req.headers["Content-Type"] = "application/x-www-form-urlencoded"
            end
            handle_response(response)
          end

          def put(path, body = {})
            ensure_authenticated
            # Proxmox API expects form-urlencoded data
            form_data = body.map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join("&")
            response = connect.put(path, form_data) do |req|
              req.headers["Cookie"] = "PVEAuthCookie=#{@ticket}"
              req.headers["CSRFPreventionToken"] = @csrf_token if @csrf_token
              req.headers["Content-Type"] = "application/x-www-form-urlencoded"
            end
            handle_response(response)
          end

          def delete(path)
            ensure_authenticated
            response = connect.delete(path) do |req|
              req.headers["Cookie"] = "PVEAuthCookie=#{@ticket}"
              req.headers["CSRFPreventionToken"] = @csrf_token if @csrf_token
            end
            handle_response(response)
          end

          def base_url
            "#{scheme}://#{hostname}:#{port}"
          end

          def with_provider_connection
            yield(self)
          end

          # Get the current node and type for a VM by querying cluster resources
          # This is necessary because VMs can be migrated between nodes
          # Returns a hash with :node and :type (qemu or lxc) keys
          def get_vm_location(vmid)
            resources = get_cluster_resources
            vm_resource = resources.find { |r| r["vmid"] == vmid.to_i && (r["type"] == "qemu" || r["type"] == "lxc") }
            
            if vm_resource
              {
                :node => vm_resource["node"],
                :type => vm_resource["type"]
              }
            else
              raise ManageIQ::Providers::Proxmox::InfraManager::APIError.new(
                "VM with ID #{vmid} not found in cluster resources",
                404,
                ""
              )
            end
          end

          private

          # Get cluster resources and cache for a short period to avoid repeated calls
          def get_cluster_resources
            @cluster_resources_cache ||= {}
            cache_key = :resources
            cache_time = 30 # Cache for 30 seconds
            
            if @cluster_resources_cache[cache_key] && 
               (Time.now - @cluster_resources_cache[cache_key][:timestamp]) < cache_time
              return @cluster_resources_cache[cache_key][:data]
            end
            
            response = get("/api2/json/cluster/resources")
            data = JSON.parse(response.body)
            resources = data["data"] || []
            # Filter to only VMs (qemu and lxc types)
            resources = resources.select { |r| r["type"] == "qemu" || r["type"] == "lxc" }
            
            @cluster_resources_cache[cache_key] = {
              :data => resources,
              :timestamp => Time.now
            }
            
            resources
          end

          def ensure_authenticated
            authenticate unless @ticket
          end

          def handle_response(response)
            if response.status >= 400
              error_msg = begin
                JSON.parse(response.body)["errors"]&.first&.dig("message") || response.body
              rescue
                response.body
              end
              raise ManageIQ::Providers::Proxmox::InfraManager::APIError.new(
                "Proxmox API error: #{error_msg}",
                response.status,
                response.body
              )
            end
            response
          end
        end
      end
    end
  end
end


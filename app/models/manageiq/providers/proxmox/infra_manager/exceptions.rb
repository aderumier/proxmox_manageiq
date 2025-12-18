module ManageIQ
  module Providers
    module Proxmox
      class InfraManager
        class ConnectionError < StandardError; end
        class AuthenticationError < StandardError; end
        class APIError < StandardError
          attr_reader :status_code, :response_body

          def initialize(message, status_code = nil, response_body = nil)
            super(message)
            @status_code = status_code
            @response_body = response_body
          end
        end
      end
    end
  end
end


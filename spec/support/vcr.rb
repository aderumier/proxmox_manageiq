require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.default_cassette_options = {
    :record => :once,
    :match_requests_on => [:method, :uri, :body]
  }

  # Filter sensitive data
  config.filter_sensitive_data("<PROXMOX_USERNAME>") do |interaction|
    interaction.request.headers["Cookie"]&.first&.match(/username=([^&]+)/)&.captures&.first
  end

  config.filter_sensitive_data("<PROXMOX_PASSWORD>") do |interaction|
    interaction.request.body&.match(/password=([^&]+)/)&.captures&.first
  end

  config.filter_sensitive_data("<PROXMOX_TICKET>") do |interaction|
    interaction.response.headers["Set-Cookie"]&.first&.match(/PVEAuthCookie=([^;]+)/)&.captures&.first
  end
end


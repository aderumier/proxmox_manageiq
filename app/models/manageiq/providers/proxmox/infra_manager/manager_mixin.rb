module ManageIQ
  module Providers
    module Proxmox
      module ManagerMixin
        extend ActiveSupport::Concern

        def required_credential_fields(_type)
          [:userid, :password]
        end

        def supported_auth_types
          %w[default]
        end

        def supported_catalog_types
          %w[proxmox]
        end

        def ensure_authentications_recorded
          return if authentications.any?

          authentications << build_authentication(:default, :userid => default_authentication.userid)
        end

        def default_authentication_type
          :default
        end
      end
    end
  end
end


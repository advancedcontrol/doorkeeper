module Doorkeeper
  class AccessToken
    include OAuth::Helpers
    include Models::Expirable
    include Models::Revocable
    include Models::Accessible
    include Models::Scopes

    belongs_to :application,
               class_name: 'Doorkeeper::Application',
               inverse_of: :access_tokens

    attr_writer :use_refresh_token

    if ::Rails.version.to_i < 4 || defined?(ProtectedAttributes)
      attr_accessible :application_id, :resource_owner_id, :expires_in,
                      :scopes, :use_refresh_token
    end

    def self.matching_token_for(application, resource_owner_or_id, scopes)
      resource_owner_id = if resource_owner_or_id.respond_to?(:to_key)
                            resource_owner_or_id.id
                          else
                            resource_owner_or_id
                          end
      token = last_authorized_token_for(application.try(:id), resource_owner_id)
      token if token && ScopeChecker.matches?(token.scopes, scopes)
    end

    def self.find_or_create_for(application, resource_owner_id, scopes, expires_in, use_refresh_token)
      if Doorkeeper.configuration.reuse_access_token
        access_token = matching_token_for(application, resource_owner_id, scopes)
        if access_token && !access_token.expired?
          return access_token
        end
      end
      create!(
        application_id:    application.try(:id),
        resource_owner_id: resource_owner_id,
        scopes:            scopes.to_s,
        expires_in:        expires_in,
        use_refresh_token: use_refresh_token
      )
    end

    def token_type
      'bearer'
    end

    def use_refresh_token?
      !!@use_refresh_token
    end

    def as_json(options = {})
      {
        resource_owner_id: resource_owner_id,
        scopes: scopes,
        expires_in_seconds: expires_in_seconds,
        application: { uid: application.try(:uid) }
      }
    end

    # It indicates whether the tokens have the same credential
    def same_credential?(access_token)
      application_id == access_token.application_id &&
        resource_owner_id == access_token.resource_owner_id
    end

    def acceptable?(scopes)
      accessible? && includes_scope?(scopes)
    end

    private

    def generate_refresh_token
      write_attribute :refresh_token, UniqueToken.generate
    end

    def generate_token
      self.token = UniqueToken.generate
    end
  end
end

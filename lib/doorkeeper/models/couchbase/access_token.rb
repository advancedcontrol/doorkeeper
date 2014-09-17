require "doorkeeper/models/couchbase/timestamps"

module Doorkeeper
  class AccessToken < ::Couchbase::Model
    design_document :dk_at

    include ::Doorkeeper::Couchbase::Timestamps
    
    attribute :resource_owner_id,
              :token,
              :expires_in,
              :scopes,
              :refresh_token

    # Couchbase views for lookup
    view  :by_resource_owner_id,
          :by_application_id,
          :by_application_id_and_resource_owner_id


    def self.by_token(token)
      find(token)
    end

    def self.by_refresh_token(refresh_token)
      id = AccessToken.bucket.get("refresh-#{refresh_token}", {quiet: true})
      if id
        AccessToken.find_by_id(id)
      end
    end

    def self.revoke_all_for(application_id, resource_owner)
      by_application_id_and_resource_owner_id({:key => [application_id, resource_owner], :stale => false}).each do |at|
        at.revoke
      end
    end


    def scopes=(value)
      write_attribute :scopes, value if value.present?
    end

    def self.last
      by_application_id_and_resource_owner_id({:stale => false, :descending => true}).first
    end

    def self.delete_all_for(application_id, resource_owner)
      by_application_id_and_resource_owner_id({:key => [application_id, resource_owner], :stale => false}).each do |at|
        at.delete
      end
    end
    private_class_method :delete_all_for

    def self.last_authorized_token_for(application_id, resource_owner_id)
      res = by_application_id_and_resource_owner_id({
        :key => [application_id, resource_owner_id],
        :stale => false}).first
    end
    private_class_method :last_authorized_token_for



    # Called from Application.rb -> authorized_for
    def self.where_owner_id(id)
      Application.find(*by_resource_owner_id({:key => id}))
    end

    # Called from Application.rb -> clean_up
    def self.where_application_id(id)
      by_application_id({:key => id, :stale => false})
    end

    private

    before_create :generate_tokens
    def generate_tokens
      generate_token
      generate_refresh_token if use_refresh_token?
      self.id = self.token
    end

    after_create :set_refresh_token, if: :use_refresh_token?
    def set_refresh_token
      # TODO:: add config for refresh token time
      expire = 3.months.to_i
      ::Doorkeeper::AccessToken.bucket.touch self.id, :ttl => expire
      ::Doorkeeper::AccessToken.bucket.set("refresh-#{self.refresh_token}", self.id, :ttl => expire)
    end

    before_delete :remove_refresh_token, if: :use_refresh_token?
    def remove_refresh_token
      ::Doorkeeper::AccessToken.bucket.delete("refresh-#{self.refresh_token}")
    end

    after_create :set_ttl, unless: :use_refresh_token?
    def set_ttl
      ::Doorkeeper::AccessToken.bucket.touch self.id, :ttl => self.expires_in
    end
  end
end

require "doorkeeper/models/couchbase/timestamps"

module Doorkeeper
  class AccessGrant < ::Couchbase::Model
    design_document :dk_ag

    include ::Doorkeeper::Couchbase::Timestamps

    attribute   :resource_owner_id,
                :token,
                :expires_in,
                :redirect_uri,
                :scopes

    view :by_application_id

  	def self.by_token(token)
      find_by_id(token)
    end

    # Called from Application.rb -> clean_up
    def self.where_application_id(id)
      by_application_id({:key => id, :stale => false})
    end

    private

    before_create :generate_tokens
    def generate_tokens
      generate_token
      self.id = self.token
    end

    # Auto remove the entry once expired
    after_create :set_ttl
    def set_ttl
      ::Doorkeeper::AccessGrant.bucket.touch self.id, :ttl => self.expires_in
    end
  end
end

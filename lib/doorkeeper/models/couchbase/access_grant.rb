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

  	def self.by_token(token)
      find_by_id(token)
    end

    private

    before_create :generate_tokens
    def generate_tokens
      generate_token
      self.id = self.token
    end
  end
end

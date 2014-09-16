module Doorkeeper
  class Application < ::Couchbase::Model
    design_document :dk_app

    attribute :name,
              :uid,
              :secret,
              :redirect_uri,
              :scopes

    attribute :created_at, :default => lambda { Time.now.to_i }

    view  :by_uid_and_secret,
          :show_all,
          :by_user_id


    def self.by_uid_and_secret(uid, secret)
      find_by_uid_and_secret({:key => [uid, secret]})
    end

    def self.by_uid(uid)
      find_by_id(uid)
    end


    def scopes=(value)
      write_attribute :scopes, value if value.present?
    end

    def self.authorized_for(resource_owner)
      AccessToken.where_owner_id(resource_owner.id)
    end

    

    
    ## TODO:: Where are these used
    def self.by_user(id)
      by_user_id({:key => [id], :stale => false})
    end
    
    def self.all
      show_all({:key => nil, :include_docs => true, :stale => false})
    end

    private

    before_create :set_id
    def set_id
      generate_uid
      generate_secret
      self.id = self.uid
    end

    # This is equivalent to has_many dependent: :destroy
    before_delete :clean_up
    def clean_up
      AccessToken.where_application_id(self.id).each do |at|
        at.delete!
      end
      AccessGrant.where_application_id(self.id).each do |at|
        at.delete!
      end
    end
  end
end

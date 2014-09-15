module Doorkeeper
  module Concerns
    module AccessToken
      def self.included(base)

        base.class_eval do
          before_validation :generate_token, on: :create
          before_validation :generate_refresh_token,
                            on: :create,
                            if: :use_refresh_token?
          
          validates :token, presence: true, uniqueness: true
          validates :refresh_token, uniqueness: true, if: :use_refresh_token?

          def self.by_token(token)
            where(token: token).first
          end

          def self.by_refresh_token(refresh_token)
            where(refresh_token: refresh_token).first
          end

          def self.revoke_all_for(application_id, resource_owner)
            where(application_id: application_id,
                  resource_owner_id: resource_owner.id,
                  revoked_at: nil)
            .map(&:revoke)
          end
        end

      end
    end
  end
end

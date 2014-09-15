module Doorkeeper
  module Concerns
    module Application
      def self.included(base)

        base.class_eval do
          has_many :access_grants, dependent: :destroy, class_name: 'Doorkeeper::AccessGrant'
          has_many :access_tokens, dependent: :destroy, class_name: 'Doorkeeper::AccessToken'

          before_validation :generate_uid, :generate_secret, on: :create
          validates :uid, uniqueness: true

          def self.by_uid_and_secret(uid, secret)
            where(uid: uid, secret: secret).first
          end

          def self.by_uid(uid)
            where(uid: uid).first
          end
        end

      end
    end
  end
end

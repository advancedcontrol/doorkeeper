module Doorkeeper
  module Concerns
    module AccessGrant

      def self.included(base)

        base.class_eval do
            before_validation :generate_token, on: :create
            validates :token, uniqueness: true
            
            def self.by_token(token)
              where(token: token).first
            end
        end

      end
      
    end
  end
end

module Doorkeeper
  class Application
    include OAuth::Helpers

    validates :name, :secret, :uid, presence: true
    validates :redirect_uri, redirect_uri: true

    if ::Rails.version.to_i < 4 || defined?(ProtectedAttributes)
      attr_accessible :name, :redirect_uri
    end

    private

    def generate_uid
      self.uid ||= UniqueToken.generate
    end

    def generate_secret
      self.secret ||= UniqueToken.generate
    end
  end
end

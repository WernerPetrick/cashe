module AppwriteAuth
  # The only code that calls Appwrite: asks who a JWT belongs to.
  class Gateway
    REJECTED_CODES = %w[401 403].freeze

    def initialize(config: Rails.configuration.x.appwrite, account_class: Appwrite::Account)
      @config = config
      @account_class = account_class
    end

    # Returns an Identity, or nil when Appwrite rejects the token.
    def identity_for(token)
      user = @account_class.new(client_for(token)).get
      Identity.new(appwrite_user_id: user.id, name: user.name)
    rescue Appwrite::Exception => e
      raise Unavailable, "Appwrite auth check failed (#{e.code})" unless rejected?(e)
    end

    private

    def client_for(token)
      Appwrite::Client.new.set_endpoint(@config.endpoint).set_project(@config.project_id).set_jwt(token)
    end

    def rejected?(error)
      REJECTED_CODES.include?(error.code.to_s)
    end
  end
end

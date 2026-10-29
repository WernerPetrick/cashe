module AppwriteAuth
  # Asks Appwrite, with the server API key, whether an email already has an account.
  class Directory
    def initialize(config: Rails.configuration.x.appwrite, api_key: Rails.application.credentials.dig(:appwrite, :api_key),
                   users_class: Appwrite::Users)
      @config = config
      @api_key = api_key
      @users_class = users_class
    end

    def account_exists?(email)
      raise Unavailable, "No Appwrite API key in credentials" if @api_key.blank?

      users_with(email).any?
    rescue Appwrite::Exception => e
      raise Unavailable, "Appwrite user lookup failed (#{e.code})"
    end

    private

    def users_with(email)
      queries = [ Appwrite::Query.equal("email", email), Appwrite::Query.limit(1) ]
      @users_class.new(client).list(queries: queries).users
    end

    def client
      Appwrite::Client.new.set_endpoint(@config.endpoint).set_project(@config.project_id).set_key(@api_key)
    end
  end
end

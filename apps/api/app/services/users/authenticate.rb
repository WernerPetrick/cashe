module Users
  # Turns a bearer token into the matching users row, creating it on first sight.
  class Authenticate
    def initialize(verifier: AppwriteAuth.verifier)
      @verifier = verifier
    end

    def call(token:)
      identity = @verifier.call(token)
      return Result.failure(:unauthorized) unless identity

      Result.success(find_or_create(identity))
    end

    private

    def find_or_create(identity)
      User.create_or_find_by!(appwrite_user_id: identity.appwrite_user_id) do |user|
        user.display_name = identity.display_name
      end
    end
  end
end

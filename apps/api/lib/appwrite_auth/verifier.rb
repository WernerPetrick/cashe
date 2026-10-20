module AppwriteAuth
  # Verifies an Appwrite JWT, caching the answer briefly keyed by a digest of the token.
  class Verifier
    def initialize(gateway: Gateway.new, cache: Rails.cache, ttl: Rails.configuration.x.appwrite.jwt_cache_seconds)
      @gateway = gateway
      @cache = cache
      @ttl = ttl
    end

    # Returns an Identity, or nil for a missing or rejected token.
    def call(token)
      return if token.blank?

      @cache.fetch(cache_key(token), expires_in: @ttl) { @gateway.identity_for(token) }
    end

    private

    def cache_key(token)
      "appwrite_auth/jwt/#{Digest::SHA256.hexdigest(token)}"
    end
  end
end

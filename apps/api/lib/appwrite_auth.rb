# Adapter between Cashe and Appwrite Auth. Everything Appwrite-specific lives here.
module AppwriteAuth
  class << self
    # Swappable so tests (and future callers) can inject a verifier.
    attr_writer :verifier

    def verifier
      @verifier ||= Verifier.new
    end
  end
end

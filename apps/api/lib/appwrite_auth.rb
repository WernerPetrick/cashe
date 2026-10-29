# Adapter between Cashe and Appwrite Auth. Everything Appwrite-specific lives here.
module AppwriteAuth
  class << self
    attr_writer :verifier, :directory

    def verifier
      @verifier ||= Verifier.new
    end

    def directory
      @directory ||= Directory.new
    end
  end
end

module Users
  # Whether an email already has an account, so the app opens sign-in or sign-up.
  class LookupAccount
    # Same rule as the app's email step: something@something.tld.
    EMAIL = /\A[^\s@]+@[^\s@]+\.[^\s@]{2,}\z/

    def initialize(directory: AppwriteAuth.directory)
      @directory = directory
    end

    def call(email:)
      email = email.to_s.strip.downcase
      return Result.failure(:invalid_email) unless EMAIL.match?(email)

      Result.success(@directory.account_exists?(email))
    end
  end
end

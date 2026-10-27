ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
Dir[File.expand_path("support/**/*.rb", __dir__)].each { |file| require file }

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Rate-limit counts and remembered pings never carry over between tests.
    setup { Rails.cache.clear }
  end
end

module ActionDispatch
  class IntegrationTest
    include ApiContract

    # Wednesday 2026-10-21 10:40 SAST: inside the tuckshop fixture's recess window.
    RECESS = Time.utc(2026, 10, 21, 8, 40)

    teardown { AppwriteAuth.verifier = nil }

    def sign_in_as(appwrite_user_id, token: "valid-jwt", name: "Pat Parent")
      identity = AppwriteAuth::Identity.new(appwrite_user_id: appwrite_user_id, name: name)
      AppwriteAuth.verifier = FakeVerifier.new({ token => identity })
      { "Authorization" => "Bearer #{token}" }
    end

    # Signs in as a fixture user and returns the auth headers.
    def as(user)
      sign_in_as(user.appwrite_user_id, name: user.display_name)
    end

    def json
      response.parsed_body
    end

    def error_code
      json.dig("error", "code")
    end
  end
end

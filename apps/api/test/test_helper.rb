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
  end
end

module ActionDispatch
  class IntegrationTest
    teardown { AppwriteAuth.verifier = nil }

    def sign_in_as(appwrite_user_id, token: "valid-jwt", name: "Pat Parent")
      identity = AppwriteAuth::Identity.new(appwrite_user_id: appwrite_user_id, name: name)
      AppwriteAuth.verifier = FakeVerifier.new({ token => identity })
      { "Authorization" => "Bearer #{token}" }
    end

    def json
      response.parsed_body
    end
  end
end

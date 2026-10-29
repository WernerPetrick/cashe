require "test_helper"

class AppwriteAuth::DirectoryTest < ActiveSupport::TestCase
  Config = Struct.new(:endpoint, :project_id)
  UserList = Struct.new(:users)

  # Fake Appwrite::Users: lists the given users or raises; remembers the queries.
  def users_class(users: [], error: nil, seen: [])
    Class.new do
      define_method(:initialize) { |client| @client = client }
      define_method(:list) { |queries:| seen.concat(queries) && (error ? raise(error) : UserList.new(users)) }
    end
  end

  def directory(api_key: "key", **outcome)
    AppwriteAuth::Directory.new(config: Config.new("https://appwrite.test/v1", "project"), api_key: api_key,
                                users_class: users_class(**outcome))
  end

  test "an email with a user has an account" do
    seen = []

    assert directory(users: [ Object.new ], seen: seen).account_exists?("pat@example.com")
    assert_includes seen, Appwrite::Query.equal("email", "pat@example.com")
  end

  test "an email with no user has no account" do
    assert_not directory(users: []).account_exists?("new@example.com")
  end

  test "raises Unavailable without an API key" do
    assert_raises(AppwriteAuth::Unavailable) { directory(api_key: nil).account_exists?("pat@example.com") }
  end

  test "raises Unavailable when Appwrite fails" do
    assert_raises(AppwriteAuth::Unavailable) do
      directory(error: Appwrite::Exception.new("boom", "500")).account_exists?("pat@example.com")
    end
  end
end

require "test_helper"

class AppwriteAuth::GatewayTest < ActiveSupport::TestCase
  Config = Struct.new(:endpoint, :project_id)
  AppwriteUser = Struct.new(:id, :name)

  # Fake Appwrite::Account: returns a user or raises the given exception.
  def account_class(user: nil, error: nil)
    Class.new do
      define_method(:initialize) { |client| @client = client }
      define_method(:get) { error ? raise(error) : user }
    end
  end

  def gateway(**outcome)
    AppwriteAuth::Gateway.new(config: Config.new("https://appwrite.test/v1", "project"), account_class: account_class(**outcome))
  end

  test "maps the Appwrite user to an identity" do
    identity = gateway(user: AppwriteUser.new("u1", "Pat")).identity_for("jwt")

    assert_equal AppwriteAuth::Identity.new(appwrite_user_id: "u1", name: "Pat"), identity
  end

  test "returns nil when Appwrite rejects the token" do
    assert_nil gateway(error: Appwrite::Exception.new("expired", "401")).identity_for("jwt")
  end

  test "raises Unavailable when Appwrite fails" do
    assert_raises(AppwriteAuth::Unavailable) do
      gateway(error: Appwrite::Exception.new("boom", "500")).identity_for("jwt")
    end
  end

  test "raises Unavailable when Appwrite can't be reached" do
    assert_raises(AppwriteAuth::Unavailable) do
      gateway(error: Appwrite::Exception.new("connection refused")).identity_for("jwt")
    end
  end
end

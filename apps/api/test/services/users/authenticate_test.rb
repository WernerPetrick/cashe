require "test_helper"

class Users::AuthenticateTest < ActiveSupport::TestCase
  def authenticate(token, identities)
    Users::Authenticate.new(verifier: FakeVerifier.new(identities)).call(token: token)
  end

  def identity(id, name = "Sam")
    AppwriteAuth::Identity.new(appwrite_user_id: id, name: name)
  end

  test "creates an adult user on first sight" do
    result = assert_difference("User.count", 1) { authenticate("jwt", "jwt" => identity("new-user")) }

    assert_predicate result, :success?
    assert_equal "Sam", result.value.display_name
    assert_predicate result.value, :adult?
  end

  test "finds the existing user" do
    result = assert_no_difference("User.count") { authenticate("jwt", "jwt" => identity("appwrite-parent", "Renamed")) }

    assert_equal users(:parent), result.value
  end

  test "falls back to a display name when Appwrite has none" do
    assert_equal "Cashe user", authenticate("jwt", "jwt" => identity("nameless", "")).value.display_name
  end

  test "fails for a rejected token" do
    result = authenticate("bad", {})

    assert_predicate result, :failure?
    assert_equal :unauthorized, result.error
  end
end

require "test_helper"

class Api::V1::MeControllerTest < ActionDispatch::IntegrationTest
  test "returns the current user" do
    get api_v1_me_path, headers: sign_in_as("appwrite-parent")

    assert_contract :ok
    assert_equal({ "id" => users(:parent).id, "display_name" => "Pat Parent", "role" => "adult" }, json)
  end

  test "rejects a missing token" do
    get api_v1_me_path

    assert_contract :unauthorized
    assert_equal "unauthorized", json.dig("error", "code")
  end

  test "rejects a token Appwrite doesn't accept" do
    sign_in_as("appwrite-parent")
    get api_v1_me_path, headers: { "Authorization" => "Bearer forged" }

    assert_contract :unauthorized
    assert_equal "unauthorized", json.dig("error", "code")
  end

  test "reports when Appwrite is unavailable" do
    AppwriteAuth.verifier = FakeVerifier.new(unavailable: true)
    get api_v1_me_path, headers: { "Authorization" => "Bearer valid-jwt" }

    assert_contract :service_unavailable
    assert_equal "auth_unavailable", json.dig("error", "code")
  end
end

require "test_helper"

class Api::V1::SessionsControllerTest < ActionDispatch::IntegrationTest
  test "creates the user on first sign-in" do
    headers = sign_in_as("appwrite-new", name: "Nia")

    assert_difference("User.count", 1) { post api_v1_session_path, headers: headers }
    assert_contract :ok
    assert_equal({ "display_name" => "Nia", "role" => "adult" }, json.except("id"))
  end

  test "returns the existing user on later sign-ins" do
    assert_no_difference("User.count") { post api_v1_session_path, headers: sign_in_as("appwrite-parent") }
    assert_equal users(:parent).id, json["id"]
  end

  test "rejects a missing token" do
    post api_v1_session_path

    assert_contract :unauthorized
    assert_equal "unauthorized", json.dig("error", "code")
  end
end

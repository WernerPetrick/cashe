require "test_helper"

class Api::V1::AccountLookupsControllerTest < ActionDispatch::IntegrationTest
  setup { AppwriteAuth.directory = FakeDirectory.new([ "pat@example.com" ]) }

  def look_up(email)
    post api_v1_account_lookups_path, params: { email: email }, as: :json
  end

  test "an email with an account exists, without a JWT" do
    look_up("pat@example.com")

    assert_contract :ok
    assert_equal({ "exists" => true }, json)
  end

  test "a new email doesn't exist" do
    look_up("new@example.com")

    assert_contract :ok
    assert_equal({ "exists" => false }, json)
  end

  test "rejects an invalid email" do
    look_up("pat@example")

    assert_contract :unprocessable_content
    assert_equal "invalid_email", error_code
  end

  test "503 when Appwrite can't be asked" do
    AppwriteAuth.directory = FakeDirectory.new(unavailable: true)
    look_up("pat@example.com")

    assert_contract :service_unavailable
    assert_equal "auth_unavailable", error_code
  end

  test "10 a minute per IP, then 429" do
    10.times { look_up("new@example.com") }
    assert_response :ok

    look_up("new@example.com")
    assert_contract :too_many_requests
    assert_equal "rate_limited", error_code
  end
end

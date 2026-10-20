require "test_helper"

class Api::V1::GiftClaimsControllerTest < ActionDispatch::IntegrationTest
  setup { travel_to Time.utc(2026, 10, 21, 8, 0) }

  def claim(user, token = "pending-gift-token")
    post api_v1_gift_claims_path, params: { token: token }, headers: as(user), as: :json
  end

  test "claims a gift" do
    claim(users(:friend))

    assert_contract :ok
    assert_equal "owner", json["role"]
    assert_equal "active", json["status"]
    assert_equal "Pat Parent", json["funder_name"]
  end

  test "the funder then sees who claimed it" do
    claim(users(:friend))
    get api_v1_wallet_path(wallets(:pending_gift)), headers: as(users(:parent))

    assert_equal "Sam Friend", json["owner_name"]
  end

  test "a used or unknown token says only that it isn't valid" do
    claim(users(:friend))
    claim(users(:stranger))

    assert_contract :unprocessable_content
    assert_equal "invalid_claim", error_code
  end

  test "the sender can't claim their own gift" do
    claim(users(:parent))

    assert_contract :unprocessable_content
    assert_equal "own_gift", error_code
  end
end

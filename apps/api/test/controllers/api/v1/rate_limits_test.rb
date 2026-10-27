require "test_helper"

# Pings, spends and gift claims are rate-limited per signed-in user.
class Api::V1::RateLimitsTest < ActionDispatch::IntegrationTest
  setup { travel_to RECESS }

  def ping(user = users(:friend))
    post api_v1_wallet_presence_pings_path(wallets(:tuckshop_gift)),
      params: { latitude: -33.9249, longitude: 18.4241, accuracy_m: 6 }, headers: as(user), as: :json
  end

  def spend(key)
    post api_v1_wallet_spends_path(wallets(:tuckshop_gift)), params: { amount_cents: 100, idempotency_key: key },
      headers: as(users(:friend)), as: :json
  end

  def claim
    post api_v1_gift_claims_path, params: { token: "not-a-token" }, headers: as(users(:friend)), as: :json
  end

  test "pings: 12 a minute, then 429" do
    12.times { ping }
    assert_response :ok

    ping
    assert_contract :too_many_requests
    assert_equal "rate_limited", error_code
  end

  test "pings: the limit resets after a minute" do
    13.times { ping }
    travel 61.seconds
    ping

    assert_response :ok
  end

  test "pings: each user has their own limit" do
    13.times { ping }
    ping(users(:parent))

    assert_response :forbidden # the funder may not ping, but isn't rate-limited
  end

  test "spends: 10 a minute, then 429" do
    10.times { |i| spend("s#{i}") }
    assert_equal "wallet_locked", error_code # refused, but each attempt counts

    spend("s10")
    assert_contract :too_many_requests
    assert_equal "rate_limited", error_code
  end

  test "gift claims: 10 a minute, then 429" do
    10.times { claim }
    assert_response :unprocessable_entity

    claim
    assert_contract :too_many_requests
    assert_equal "rate_limited", error_code
  end
end

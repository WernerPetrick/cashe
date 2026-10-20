require "test_helper"

class Api::V1::Wallets::PresencePingsControllerTest < ActionDispatch::IntegrationTest
  INSIDE = { latitude: -33.92491234, longitude: 18.42411234, accuracy_m: 6 }.freeze

  setup { travel_to RECESS }

  def ping(user = users(:friend), wallet: wallets(:tuckshop_gift), **body)
    post api_v1_wallet_presence_pings_path(wallet), params: INSIDE.merge(body), headers: as(user), as: :json
  end

  test "reports dwell progress inside the zone" do
    ping

    assert_contract :ok
    assert_equal({ "status" => "dwelling", "inside_zone" => true, "in_time_window" => true, "dwell_progress_seconds" => 0,
      "dwell_required_seconds" => 30, "unlocked_until" => nil, "reason" => nil }, json)
  end

  test "unlocks after the place's dwell time" do
    4.times { ping && travel(10.seconds) }

    assert_contract :ok
    assert_equal "unlocked", json["status"]
    assert_not_nil json["unlocked_until"]
  end

  test "rejects a mock location on screen" do
    ping(is_mocked: true)

    assert_contract :ok
    assert_equal "rejected", json["status"]
    assert_equal "mock_location", json["reason"]
  end

  test "never logs the coordinates" do
    log = Rails.root.join("log/test.log")
    before = log.size
    ping

    assert_no_match(/33\.9249|18\.4241/, log.read.byteslice(before..))
  end

  test "rejects a ping it can't read" do
    ping(latitude: "north")

    assert_contract :unprocessable_content
    assert_equal "invalid_ping", error_code
  end

  test "the funder can't ping for the recipient" do
    ping(users(:parent))

    assert_contract :forbidden
  end

  test "a stranger can't see the wallet" do
    ping(users(:stranger))

    assert_contract :not_found
  end

  test "refuses a wallet that is no longer active" do
    wallets(:tuckshop_gift).update!(status: :expired)
    ping

    assert_contract :conflict
    assert_equal "wallet_closed", error_code
  end
end

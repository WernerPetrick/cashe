require "test_helper"

class Api::V1::WalletsControllerTest < ActionDispatch::IntegrationTest
  def fund(wallet, cents) = Ledger::Deposit.new.call(wallet: wallet, amount_cents: cents, key: SecureRandom.hex)

  test "lists wallets I own or funded, with balances" do
    fund(wallets(:bike_goal), 12_000)
    get api_v1_wallets_path, headers: as(users(:parent))

    assert_contract :ok
    assert_equal %w[bike_goal pending_gift tuckshop_gift].map { wallets(_1).id }.sort, json["wallets"].pluck("id").sort
    assert_equal 12_000, json["wallets"].find { _1["id"] == wallets(:bike_goal).id }["balance_cents"]
  end

  test "lists only what a stranger is part of" do
    get api_v1_wallets_path, headers: as(users(:stranger))

    assert_contract :ok
    assert_empty json["wallets"]
  end

  test "shows a funder who claimed their gift" do
    get api_v1_wallet_path(wallets(:tuckshop_gift)), headers: as(users(:parent))

    assert_contract :ok
    assert_equal "funder", json["role"]
    assert_equal "Sam Friend", json["owner_name"]
    assert_equal [ { "days_of_week" => [ 1, 2, 3, 4, 5 ], "starts_at" => "10:30", "ends_at" => "11:00",
      "time_zone" => "Africa/Johannesburg" } ], json["time_windows"]
  end

  test "hides another person's wallet" do
    get api_v1_wallet_path(wallets(:tuckshop_gift)), headers: as(users(:stranger))

    assert_contract :not_found
  end

  test "shows the spend window to the owner but never to the funder" do
    travel_to RECESS
    session = PresenceSession.create!(wallet: wallets(:tuckshop_gift), user: users(:friend), entered_at: 1.minute.ago,
      last_ping_at: Time.current, unlocked_at: Time.current)
    Unlock.create!(wallet: wallets(:tuckshop_gift), presence_session: session, unlocked_until: 10.minutes.from_now)

    get api_v1_wallet_path(wallets(:tuckshop_gift)), headers: as(users(:friend))
    assert_not_nil json["unlocked_until"]

    get api_v1_wallet_path(wallets(:tuckshop_gift)), headers: as(users(:parent))
    assert_contract :ok
    assert_nil json["unlocked_until"]
  end

  test "creates a gift and returns its claim link once" do
    body = { kind: "gift", name: "Coffee on me", place_id: places(:tuckshop).id, currency: "ZAR",
      time_windows: [ { days_of_week: [ 1, 2, 3, 4, 5 ], starts_at: "10:30", ends_at: "11:00", time_zone: "Africa/Johannesburg" } ] }
    post api_v1_wallets_path, params: body, headers: as(users(:friend)), as: :json

    assert_contract :created
    assert_equal "pending", json["status"]
    assert_match %r{\Ahttps://cashe.app/claim/}, json["claim_url"]
    assert_equal 1, json["time_windows"].size

    get api_v1_wallet_path(json["id"]), headers: as(users(:friend))
    assert_not json.key?("claim_url")
  end

  test "creates a savings goal" do
    body = { kind: "goal", name: "Bike", place_id: places(:mikes_bikes).id, currency: "ZAR", target_cents: 450_000 }
    post api_v1_wallets_path, params: body, headers: as(users(:friend)), as: :json

    assert_contract :created
    assert_equal "owner", json["role"]
    assert_nil json["claim_url"]
  end

  test "reports invalid wallet details" do
    post api_v1_wallets_path, params: { kind: "gift", name: "", place_id: 0, currency: "BTC" },
      headers: as(users(:friend)), as: :json

    assert_contract :unprocessable_content
    assert_equal "validation_failed", error_code
    assert_includes json.dig("error", "details"), "Place must exist"
  end
end

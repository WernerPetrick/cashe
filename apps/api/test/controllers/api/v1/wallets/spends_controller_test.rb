require "test_helper"

class Api::V1::Wallets::SpendsControllerTest < ActionDispatch::IntegrationTest
  setup do
    travel_to RECESS
    Ledger::Deposit.new.call(wallet: wallets(:tuckshop_gift), amount_cents: 1000, key: "top-up")
  end

  def unlock!
    session = PresenceSession.create!(wallet: wallets(:tuckshop_gift), user: users(:friend), entered_at: 1.minute.ago,
      last_ping_at: Time.current, unlocked_at: Time.current)
    Unlock.create!(wallet: wallets(:tuckshop_gift), presence_session: session, unlocked_until: 10.minutes.from_now)
  end

  def spend(user = users(:friend), amount_cents: 300)
    post api_v1_wallet_spends_path(wallets(:tuckshop_gift)), params: { amount_cents: amount_cents, idempotency_key: "s1" },
      headers: as(user), as: :json
  end

  test "spends during an unlock and names the place" do
    unlock!
    spend

    assert_contract :created
    assert_equal(-300, json["amount_cents"])
    assert_equal "School Tuckshop", json["place_name"]
  end

  test "refuses while the wallet is locked" do
    spend

    assert_contract :conflict
    assert_equal "wallet_locked", error_code
  end

  test "refuses to overdraw" do
    unlock!
    spend(amount_cents: 5000)

    assert_contract :unprocessable_content
    assert_equal "insufficient_funds", error_code
  end

  test "the funder can't spend the recipient's gift" do
    unlock!
    spend(users(:parent))

    assert_contract :forbidden
  end

  test "a stranger can't see the wallet" do
    spend(users(:stranger))

    assert_contract :not_found
  end
end

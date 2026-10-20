require "test_helper"

class Api::V1::Wallets::CancellationsControllerTest < ActionDispatch::IntegrationTest
  def cancel(wallet, user)
    post api_v1_wallet_cancellation_path(wallet), headers: as(user), as: :json
  end

  test "the sender cancels an unclaimed gift and gets the money back" do
    Ledger::Deposit.new.call(wallet: wallets(:pending_gift), amount_cents: 5000, key: "k")
    cancel(wallets(:pending_gift), users(:parent))

    assert_contract :ok
    assert_equal "cancelled", json["status"]
    assert_equal 0, json["balance_cents"]
  end

  test "a claimed gift can't be cancelled" do
    cancel(wallets(:tuckshop_gift), users(:parent))

    assert_contract :conflict
    assert_equal "not_cancellable", error_code
  end

  test "the recipient can't cancel" do
    cancel(wallets(:tuckshop_gift), users(:friend))

    assert_contract :forbidden
  end

  test "a goal isn't a gift to cancel" do
    cancel(wallets(:bike_goal), users(:parent))

    assert_contract :forbidden
  end

  test "a stranger can't see the gift" do
    cancel(wallets(:pending_gift), users(:stranger))

    assert_contract :not_found
  end
end

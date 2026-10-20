require "test_helper"

class Api::V1::Wallets::DepositsControllerTest < ActionDispatch::IntegrationTest
  def deposit(wallet, user, amount_cents: 1000, key: "top-up-1")
    post api_v1_wallet_deposits_path(wallet), params: { amount_cents: amount_cents, idempotency_key: key },
      headers: as(user), as: :json
  end

  test "the funder tops up a gift" do
    deposit(wallets(:tuckshop_gift), users(:parent))

    assert_contract :created
    assert_equal "deposit", json["kind"]
    assert_equal 1000, json["amount_cents"]
  end

  test "resending the same key returns the original deposit" do
    deposit(wallets(:tuckshop_gift), users(:parent))
    first = json["id"]
    deposit(wallets(:tuckshop_gift), users(:parent))

    assert_contract :created
    assert_equal first, json["id"]
    assert_equal 1, wallets(:tuckshop_gift).ledger_entries.count
  end

  test "a reused key with another amount is a conflict" do
    deposit(wallets(:tuckshop_gift), users(:parent))
    deposit(wallets(:tuckshop_gift), users(:parent), amount_cents: 5)

    assert_contract :conflict
    assert_equal "idempotency_conflict", error_code
  end

  test "the recipient can't top up a gift" do
    deposit(wallets(:tuckshop_gift), users(:friend))

    assert_contract :forbidden
  end

  test "a stranger can't see the wallet" do
    deposit(wallets(:tuckshop_gift), users(:stranger))

    assert_contract :not_found
  end

  test "rejects a non-positive amount" do
    deposit(wallets(:tuckshop_gift), users(:parent), amount_cents: 0)

    assert_contract :unprocessable_content
    assert_equal "invalid_amount", error_code
  end

  test "refuses a closed wallet" do
    wallets(:pending_gift).update!(status: :cancelled, claim_token_digest: nil)
    deposit(wallets(:pending_gift), users(:parent))

    assert_contract :conflict
    assert_equal "wallet_closed", error_code
  end
end

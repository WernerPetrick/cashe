require "test_helper"

class Ledger::DepositTest < ActiveSupport::TestCase
  setup { @clock = FixedClock.new(Time.utc(2026, 10, 21, 8, 40)) }

  def deposit(wallet, cents, key: "k1")
    Ledger::Deposit.new(clock: @clock).call(wallet: wallet, amount_cents: cents, key: key)
  end

  def balance(wallet) = WalletBalances.new.for(wallet)

  test "adds money to the wallet" do
    result = deposit(wallets(:bike_goal), 2500)

    assert_predicate result, :success?
    assert_predicate result.value, :deposit?
    assert_equal Money.new(2500, "ZAR"), balance(wallets(:bike_goal))
  end

  test "replays a repeated key instead of depositing twice" do
    first = deposit(wallets(:bike_goal), 2500).value
    again = deposit(wallets(:bike_goal), 2500)

    assert_equal first, again.value
    assert_equal Money.new(2500, "ZAR"), balance(wallets(:bike_goal))
  end

  test "refuses a reused key with a different amount" do
    deposit(wallets(:bike_goal), 2500)

    assert_equal :idempotency_conflict, deposit(wallets(:bike_goal), 9999).error
  end

  test "scopes keys to the wallet" do
    deposit(wallets(:bike_goal), 2500)

    assert_predicate deposit(wallets(:tuckshop_gift), 100), :success?
  end

  test "rejects amounts that aren't positive whole cents" do
    [ 0, -5, 10.5, "100" ].each do |amount|
      assert_equal :invalid_amount, deposit(wallets(:bike_goal), amount).error
    end
  end

  test "requires a key" do
    assert_equal :invalid_idempotency_key, deposit(wallets(:bike_goal), 100, key: " ").error
  end

  test "accepts a gift that is waiting to be claimed" do
    assert_predicate deposit(wallets(:pending_gift), 1000), :success?
  end

  test "refuses closed wallets" do
    wallets(:pending_gift).update!(status: :cancelled, claim_token_digest: nil)

    assert_equal :wallet_closed, deposit(wallets(:pending_gift), 1000).error
  end

  test "refuses a gift past its expiry" do
    wallets(:tuckshop_gift).update!(expires_at: @clock.current - 1)

    assert_equal :wallet_closed, deposit(wallets(:tuckshop_gift), 1000).error
  end
end

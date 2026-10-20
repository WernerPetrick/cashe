require "test_helper"

class Ledger::SpendTest < ActiveSupport::TestCase
  setup do
    @clock = FixedClock.new(Time.utc(2026, 10, 21, 8, 40))
    @wallet = wallets(:tuckshop_gift)
    Ledger::Deposit.new(clock: @clock).call(wallet: @wallet, amount_cents: 1000, key: "top-up")
  end

  def unlock!(minutes: 10)
    session = PresenceSession.create!(wallet: @wallet, user: users(:friend), entered_at: @clock.current - 30,
      last_ping_at: @clock.current, unlocked_at: @clock.current)
    Unlock.create!(wallet: @wallet, presence_session: session, unlocked_until: @clock.current + minutes * 60)
  end

  def spend(cents, key: "s1")
    Ledger::Spend.new(clock: @clock).call(wallet: @wallet, amount_cents: cents, key: key)
  end

  def balance = WalletBalances.new.for(@wallet)

  test "refuses to spend while the wallet is locked" do
    assert_equal :wallet_locked, spend(300).error
    assert_equal Money.new(1000, "USD"), balance
  end

  test "spends during an unlock and records which unlock allowed it" do
    unlock = unlock!
    result = spend(300)

    assert_predicate result, :success?
    assert_equal(-300, result.value.amount_cents)
    assert_equal unlock, result.value.unlock
    assert_equal Money.new(700, "USD"), balance
  end

  test "refuses to overdraw" do
    unlock!

    assert_equal :insufficient_funds, spend(1001).error
    assert_equal Money.new(1000, "USD"), balance
  end

  test "locks again when the spend window ends" do
    unlock!
    @clock.advance(10 * 60)

    assert_equal :wallet_locked, spend(300).error
  end

  test "still replays an earlier spend after the window ends" do
    unlock!
    first = spend(300).value
    @clock.advance(15 * 60)

    assert_equal first, spend(300).value
    assert_equal Money.new(700, "USD"), balance
  end

  test "refuses a gift that is still waiting to be claimed" do
    @wallet = wallets(:pending_gift)

    assert_equal :wallet_closed, spend(100).error
  end
end

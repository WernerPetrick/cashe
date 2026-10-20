require "test_helper"

class Gifts::ExpireTest < ActiveSupport::TestCase
  setup { @clock = FixedClock.new(Time.utc(2026, 10, 21, 8, 0)) }

  def expire(wallet) = Gifts::Expire.new(clock: @clock).call(wallet: wallet)
  def fund(wallet, cents) = Ledger::Deposit.new(clock: @clock).call(wallet: wallet, amount_cents: cents, key: "k")

  test "leaves an unclaimed gift alone inside its claim window" do
    assert_equal :not_due, expire(wallets(:pending_gift)).error
  end

  test "refunds an unclaimed gift after its claim window" do
    fund(wallets(:pending_gift), 2000)
    @clock.advance(2.days)

    assert_predicate expire(wallets(:pending_gift)), :success?
    assert_predicate wallets(:pending_gift).reload, :expired?
    assert_equal Money.zero("ZAR"), WalletBalances.new.for(wallets(:pending_gift))
  end

  test "refunds what is left of a claimed gift after the sender's expiry date" do
    wallet = wallets(:tuckshop_gift)
    fund(wallet, 1000)
    wallet.update!(expires_at: @clock.current + 60)
    @clock.advance(61)

    assert_predicate expire(wallet), :success?
    assert_equal Money.zero("USD"), WalletBalances.new.for(wallet)
  end

  test "never expires a claimed gift without an expiry date" do
    @clock.advance(365.days)

    assert_equal :not_due, expire(wallets(:tuckshop_gift)).error
  end

  test "is safe to run twice" do
    fund(wallets(:pending_gift), 2000)
    @clock.advance(3.days)
    expire(wallets(:pending_gift))

    assert_equal :not_due, expire(wallets(:pending_gift)).error
    assert_equal 1, wallets(:pending_gift).ledger_entries.refund.count
  end
end

require "test_helper"

class Gifts::ExpireDueTest < ActiveSupport::TestCase
  setup { @clock = FixedClock.new(Time.utc(2026, 10, 21, 8, 0)) }

  def expire_due = Gifts::ExpireDue.new(clock: @clock).call
  def fund(wallet, cents) = Ledger::Deposit.new(clock: @clock).call(wallet: wallet, amount_cents: cents, key: "k")

  test "does nothing while every gift is still in time" do
    assert_equal 0, expire_due.value
    assert_predicate wallets(:pending_gift).reload, :pending?
  end

  test "refunds unclaimed and expired gifts together" do
    fund(wallets(:pending_gift), 2000)
    fund(wallets(:tuckshop_gift), 1000)
    wallets(:tuckshop_gift).update!(expires_at: @clock.current + 1.day)
    @clock.advance(2.days)

    assert_equal 2, expire_due.value
    assert_predicate wallets(:pending_gift).reload, :expired?
    assert_predicate wallets(:tuckshop_gift).reload, :expired?
    assert_equal Money.zero("USD"), WalletBalances.new.for(wallets(:tuckshop_gift))
  end

  test "leaves goals and gifts without an expiry date alone" do
    @clock.advance(30.days)
    expire_due

    assert_predicate wallets(:tuckshop_gift).reload, :active?
    assert_predicate wallets(:bike_goal).reload, :active?
  end

  test "running twice refunds once" do
    fund(wallets(:pending_gift), 2000)
    @clock.advance(2.days)
    expire_due

    assert_equal 0, expire_due.value
    assert_equal 1, wallets(:pending_gift).ledger_entries.refund.count
  end
end

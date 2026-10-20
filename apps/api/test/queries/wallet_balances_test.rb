require "test_helper"

class WalletBalancesTest < ActiveSupport::TestCase
  test "sums each wallet's entries in its own currency" do
    Ledger::Deposit.new.call(wallet: wallets(:bike_goal), amount_cents: 2500, key: "a")
    Ledger::Deposit.new.call(wallet: wallets(:bike_goal), amount_cents: 500, key: "b")

    balances = WalletBalances.new.for_all([ wallets(:bike_goal), wallets(:pending_gift) ])

    assert_equal Money.new(3000, "ZAR"), balances[wallets(:bike_goal).id]
    assert_equal Money.zero("ZAR"), balances[wallets(:pending_gift).id]
  end
end

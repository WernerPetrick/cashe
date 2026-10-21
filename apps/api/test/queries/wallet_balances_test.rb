require "test_helper"

class WalletBalancesTest < ActiveSupport::TestCase
  test "sums each wallet's entries in its own currency" do
    Ledger::Deposit.new.call(wallet: wallets(:bike_goal), amount_cents: 2500, key: "a")
    Ledger::Deposit.new.call(wallet: wallets(:bike_goal), amount_cents: 500, key: "b")

    balances = WalletBalances.new.for_all([ wallets(:bike_goal), wallets(:pending_gift) ])

    assert_equal Money.new(3000, "ZAR"), balances[wallets(:bike_goal).id]
    assert_equal Money.zero("ZAR"), balances[wallets(:pending_gift).id]
  end

  test "funded counts deposits only, not what was spent or refunded" do
    wallet = wallets(:pending_gift)
    Ledger::Deposit.new.call(wallet: wallet, amount_cents: 5000, key: "a")
    Gifts::Cancel.new.call(wallet: wallet)

    assert_equal 5000, WalletBalances.new.funded_cents_for(wallet)
    assert_equal({ wallet.id => 5000 }, WalletBalances.new.funded_cents_for_all([ wallet ]))
    assert_equal Money.zero("ZAR"), WalletBalances.new.for(wallet)
  end
end

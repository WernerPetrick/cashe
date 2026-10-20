require "test_helper"

class Gifts::CancelTest < ActiveSupport::TestCase
  def cancel(wallet) = Gifts::Cancel.new.call(wallet: wallet)

  test "refunds an unclaimed gift and kills its claim link" do
    wallet = wallets(:pending_gift)
    Ledger::Deposit.new.call(wallet: wallet, amount_cents: 5000, key: "k")

    result = cancel(wallet)

    assert_predicate result, :success?
    assert_predicate wallet.reload, :cancelled?
    assert_nil wallet.claim_token_digest
    assert_equal Money.zero("ZAR"), WalletBalances.new.for(wallet)
    assert_equal [ -5000 ], wallet.ledger_entries.refund.pluck(:amount_cents)
  end

  test "works on an empty gift" do
    assert_predicate cancel(wallets(:pending_gift)), :success?
  end

  test "refuses once the gift has been claimed" do
    assert_equal :not_cancellable, cancel(wallets(:tuckshop_gift)).error
  end
end

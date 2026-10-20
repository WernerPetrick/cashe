require "test_helper"

class Api::V1::Wallets::LedgerEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    3.times { |i| Ledger::Deposit.new.call(wallet: wallets(:bike_goal), amount_cents: 100 * (i + 1), key: "d#{i}") }
  end

  test "pages through history, newest first" do
    get api_v1_wallet_ledger_entries_path(wallets(:bike_goal), limit: 2), headers: as(users(:parent))

    assert_contract :ok
    assert_equal [ 300, 200 ], json["entries"].pluck("amount_cents")

    get api_v1_wallet_ledger_entries_path(wallets(:bike_goal), limit: 2, before: json["next_before"]), headers: as(users(:parent))

    assert_contract :ok
    assert_equal [ 100 ], json["entries"].pluck("amount_cents")
    assert_nil json["next_before"]
  end

  test "a stranger can't see the history" do
    get api_v1_wallet_ledger_entries_path(wallets(:bike_goal)), headers: as(users(:stranger))

    assert_contract :not_found
  end
end

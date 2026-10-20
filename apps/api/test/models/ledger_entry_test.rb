require "test_helper"

class LedgerEntryTest < ActiveSupport::TestCase
  def deposit
    LedgerEntry.create!(wallet: wallets(:bike_goal), kind: :deposit, amount_cents: 1000, idempotency_key: "k1")
  end

  test "is read-only once saved" do
    entry = deposit

    assert_raises(ActiveRecord::ReadOnlyRecord) { entry.update!(amount_cents: 5) }
    assert_raises(ActiveRecord::ReadOnlyRecord) { entry.destroy! }
  end

  test "the database refuses updates and deletes" do
    entry = deposit

    assert_raises(ActiveRecord::StatementInvalid) { LedgerEntry.where(id: entry.id).update_all(amount_cents: 1) }
    assert_raises(ActiveRecord::StatementInvalid) { LedgerEntry.where(id: entry.id).delete_all }
  end

  test "the database requires the sign to match the kind" do
    assert_raises(ActiveRecord::StatementInvalid) do
      LedgerEntry.insert!({ wallet_id: wallets(:bike_goal).id, kind: "deposit", amount_cents: -5, idempotency_key: "k2" })
    end
  end

  test "the database keeps idempotency keys unique" do
    deposit

    assert_raises(ActiveRecord::RecordNotUnique) { deposit }
  end
end

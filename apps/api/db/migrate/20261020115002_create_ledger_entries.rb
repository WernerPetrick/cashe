class CreateLedgerEntries < ActiveRecord::Migration[8.1]
  def change
    # Append-only: no updated_at, and a trigger refuses UPDATE and DELETE.
    create_table :ledger_entries do |t|
      t.references :wallet, null: false, foreign_key: true
      t.bigint :amount_cents, null: false
      t.string :kind, null: false
      t.string :idempotency_key, null: false, index: { unique: true }
      t.references :unlock, foreign_key: true
      t.datetime :created_at, null: false
    end

    add_check_constraint :ledger_entries, "kind IN ('deposit', 'spend', 'refund')", name: "ledger_entries_kind"
    add_check_constraint :ledger_entries,
      "(kind = 'deposit' AND amount_cents > 0) OR (kind IN ('spend', 'refund') AND amount_cents < 0)",
      name: "ledger_entries_sign_matches_kind"
    add_check_constraint :ledger_entries, "kind <> 'spend' OR unlock_id IS NOT NULL", name: "ledger_entries_spend_has_unlock"

    reversible do |direction|
      direction.up { create_append_only_trigger }
      direction.down { drop_append_only_trigger }
    end
  end

  private

  def create_append_only_trigger
    execute <<~SQL
      CREATE FUNCTION ledger_entries_append_only() RETURNS trigger AS $$
      BEGIN
        RAISE EXCEPTION 'ledger_entries is append-only: % is not allowed', TG_OP;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER ledger_entries_append_only
        BEFORE UPDATE OR DELETE ON ledger_entries
        FOR EACH ROW EXECUTE FUNCTION ledger_entries_append_only();
    SQL
  end

  def drop_append_only_trigger
    execute <<~SQL
      DROP TRIGGER ledger_entries_append_only ON ledger_entries;
      DROP FUNCTION ledger_entries_append_only();
    SQL
  end
end

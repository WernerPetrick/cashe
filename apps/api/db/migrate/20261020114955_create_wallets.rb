class CreateWallets < ActiveRecord::Migration[8.1]
  def change
    create_table :wallets do |t|
      t.string :kind, null: false
      t.references :owner, foreign_key: { to_table: :users }
      t.references :funder, null: false, foreign_key: { to_table: :users }
      t.references :place, null: false, foreign_key: true
      t.string :name, null: false, limit: 100
      t.string :currency, null: false, limit: 3
      t.string :status, null: false
      t.bigint :target_cents
      t.datetime :expires_at
      t.string :claim_token_digest, index: { unique: true }
      t.datetime :claim_expires_at
      t.datetime :claimed_at
      t.timestamps
    end

    add_wallet_checks
  end

  private

  def add_wallet_checks
    {
      wallets_kind: "kind IN ('goal', 'gift')",
      wallets_status: "status IN ('pending', 'active', 'cancelled', 'expired')",
      wallets_currency_format: "currency ~ '^[A-Z]{3}$'",
      wallets_target_positive: "target_cents IS NULL OR target_cents > 0",
      # A goal is always its funder's own wallet and never waits for a claim.
      wallets_goal_owned: "kind <> 'goal' OR (owner_id = funder_id AND status <> 'pending' AND claim_token_digest IS NULL)",
      # A gift has an owner exactly when it has been claimed, and never its own funder.
      wallets_gift_claimed: "kind <> 'gift' OR ((owner_id IS NULL) = (claimed_at IS NULL) AND owner_id IS DISTINCT FROM funder_id)",
      wallets_pending_unclaimed: "status <> 'pending' OR (owner_id IS NULL AND claim_token_digest IS NOT NULL AND claim_expires_at IS NOT NULL)"
    }.each { |name, check| add_check_constraint :wallets, check, name: name.to_s }
  end
end

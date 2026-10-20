class CreatePresenceSessions < ActiveRecord::Migration[8.1]
  def change
    # Timestamps only: no coordinates are ever stored (privacy rules).
    create_table :presence_sessions do |t|
      t.references :wallet, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :entered_at, null: false
      t.datetime :last_ping_at, null: false
      t.datetime :unlocked_at
      t.datetime :ended_at
      t.timestamps
    end

    add_index :presence_sessions, [ :wallet_id, :user_id ], unique: true, where: "ended_at IS NULL",
      name: "index_presence_sessions_one_open_per_wallet_user"
    add_check_constraint :presence_sessions, "last_ping_at >= entered_at", name: "presence_sessions_ping_order"
    add_check_constraint :presence_sessions, "ended_at IS NULL OR ended_at >= entered_at", name: "presence_sessions_end_order"
  end
end

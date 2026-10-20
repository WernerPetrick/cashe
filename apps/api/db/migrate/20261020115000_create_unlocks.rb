class CreateUnlocks < ActiveRecord::Migration[8.1]
  def change
    create_table :unlocks do |t|
      t.references :wallet, null: false, foreign_key: true
      t.references :presence_session, null: false, foreign_key: true, index: { unique: true }
      t.datetime :unlocked_until, null: false
      t.timestamps
    end

    add_index :unlocks, [ :wallet_id, :unlocked_until ]
  end
end

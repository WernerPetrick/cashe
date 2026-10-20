class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :appwrite_user_id, null: false, index: { unique: true }
      t.string :display_name, null: false, limit: 100
      t.string :role, null: false, default: "adult"
      t.timestamps
    end

    add_check_constraint :users, "role IN ('adult', 'child')", name: "users_role_check"
  end
end

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_20_074700) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "postgis"

  create_table "users", force: :cascade do |t|
    t.string "appwrite_user_id", null: false
    t.string "display_name", limit: 100, null: false
    t.string "role", default: "adult", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appwrite_user_id"], name: "index_users_on_appwrite_user_id", unique: true
    t.check_constraint "role::text = ANY (ARRAY['adult'::character varying, 'child'::character varying]::text[])", name: "users_role_check"
  end
end

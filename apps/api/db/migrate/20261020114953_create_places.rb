class CreatePlaces < ActiveRecord::Migration[8.1]
  def change
    create_table :places do |t|
      t.string :name, null: false, limit: 120
      t.st_point :location, geographic: true, srid: 4326, null: false
      t.integer :radius_m, null: false
      t.integer :dwell_seconds, null: false
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :places, :location, using: :gist
    add_check_constraint :places, "radius_m BETWEEN 10 AND 1000", name: "places_radius_range"
    add_check_constraint :places, "dwell_seconds BETWEEN 10 AND 3600", name: "places_dwell_range"
  end
end

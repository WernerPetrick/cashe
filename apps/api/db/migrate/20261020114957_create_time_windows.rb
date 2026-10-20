class CreateTimeWindows < ActiveRecord::Migration[8.1]
  def change
    create_table :time_windows do |t|
      t.references :wallet, null: false, foreign_key: true
      # 0 = Sunday … 6 = Saturday, matching Ruby's Time#wday.
      t.integer :days_of_week, array: true, null: false
      t.time :starts_at, null: false
      t.time :ends_at, null: false
      t.string :time_zone, null: false
      t.timestamps
    end

    add_check_constraint :time_windows,
      "cardinality(days_of_week) BETWEEN 1 AND 7 AND days_of_week <@ ARRAY[0,1,2,3,4,5,6]",
      name: "time_windows_days_valid"
    # Windows don't cross midnight; an overnight window is two windows.
    add_check_constraint :time_windows, "starts_at < ends_at", name: "time_windows_ordered"
  end
end

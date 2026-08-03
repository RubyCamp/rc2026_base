class CreateAvailabilities < ActiveRecord::Migration[8.1]
  def change
    create_table :availabilities do |t|
      t.references :staff_member, null: false, foreign_key: true
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :status, null: false, default: "available"
      t.text :notes

      t.timestamps
    end

    add_index :availabilities, %i[staff_member_id starts_at]

    add_check_constraint :availabilities,
                         "ends_at > starts_at",
                         name: "availabilities_time_range_check"

    add_check_constraint :availabilities,
                         "status IN ('available', 'unavailable')",
                         name: "availabilities_status_check"
  end
end

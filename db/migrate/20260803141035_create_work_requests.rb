class CreateWorkRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :work_requests do |t|
      t.references :business, null: false, foreign_key: true
      t.references :required_skill,
                   null: false,
                   foreign_key: { to_table: :skills }
      t.string :title, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.integer :required_staff_count, null: false
      t.string :status, null: false, default: "draft"
      t.text :notes

      t.timestamps
    end

    add_index :work_requests, :starts_at
    add_index :work_requests, :status

    add_check_constraint :work_requests,
                         "ends_at > starts_at",
                         name: "work_requests_time_range_check"

    add_check_constraint :work_requests,
                         "required_staff_count > 0",
                         name: "work_requests_required_staff_count_check"

    add_check_constraint :work_requests,
                         "status IN ('open', 'draft', 'confirmed', 'cancelled')",
                         name: "work_requests_status_check"
  end
end

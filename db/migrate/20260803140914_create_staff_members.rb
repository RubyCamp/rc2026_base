class CreateStaffMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :staff_members do |t|
      t.string :name, null: false
      t.string :employment_status, null: false, default: "active"
      t.text :notes

      t.timestamps
    end

    add_index :staff_members, :name
    add_index :staff_members, :employment_status

    add_check_constraint :staff_members,
                         "employment_status IN ('active', 'inactive')",
                         name: "staff_members_employment_status_check"
  end
end

class CreateAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :assignments do |t|
      t.references :work_request, null: false, foreign_key: true
      t.references :staff_member, null: false, foreign_key: true
      t.string :status, null: false, default: "draft"
      t.text :notes

      t.timestamps
    end

    add_index :assignments,
              %i[work_request_id staff_member_id],
              unique: true

    add_index :assignments, :status

    add_check_constraint :assignments,
                         "status IN ('draft', 'confirmed')",
                         name: "assignments_status_check"
  end
end

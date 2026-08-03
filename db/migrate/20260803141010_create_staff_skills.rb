class CreateStaffSkills < ActiveRecord::Migration[8.1]
  def change
    create_table :staff_skills do |t|
      t.references :staff_member, null: false, foreign_key: true
      t.references :skill, null: false, foreign_key: true
      t.string :proficiency_label, null: false

      t.timestamps
    end

    add_index :staff_skills,
              %i[staff_member_id skill_id],
              unique: true
  end
end

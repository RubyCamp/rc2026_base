class StaffSkill < ApplicationRecord
  belongs_to :staff_member
  belongs_to :skill

  validates :proficiency_label, presence: true
  validates :skill_id, uniqueness: { scope: :staff_member_id }
end

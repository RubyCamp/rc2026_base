class StaffMember < ApplicationRecord
  has_many :availabilities, dependent: :destroy
  has_many :assignments, dependent: :restrict_with_error
  has_many :staff_skills, dependent: :destroy
  has_many :skills, through: :staff_skills

  enum :employment_status, { active: "active", inactive: "inactive" }, validate: true

  validates :name, presence: true
end

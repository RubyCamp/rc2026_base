class Skill < ApplicationRecord
  has_many :staff_skills, dependent: :restrict_with_error
  has_many :staff_members, through: :staff_skills
  has_many :work_requests,
           foreign_key: :required_skill_id,
           inverse_of: :required_skill,
           dependent: :restrict_with_error

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
end

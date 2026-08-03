class WorkRequest < ApplicationRecord
  belongs_to :business
  belongs_to :required_skill,
             class_name: "Skill",
             inverse_of: :work_requests

  has_many :assignments, dependent: :destroy
  has_many :staff_members, through: :assignments

  enum :status,
       {
         open: "open",
         draft: "draft",
         confirmed: "confirmed",
         cancelled: "cancelled"
       },
       validate: true

  validates :title, :starts_at, :ends_at, presence: true
  validates :required_staff_count,
            numericality: {
              only_integer: true,
              greater_than: 0
            }

  validate :ends_at_after_starts_at

  private

  def ends_at_after_starts_at
    return if starts_at.blank? || ends_at.blank? || ends_at > starts_at

    errors.add(:ends_at, "は開始日時より後にしてください")
  end
end

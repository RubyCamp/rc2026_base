class Availability < ApplicationRecord
  belongs_to :staff_member

  enum :status, { available: "available", unavailable: "unavailable" }, validate: true

  validates :starts_at, :ends_at, presence: true
  validate :ends_at_after_starts_at

  private

  def ends_at_after_starts_at
    return if starts_at.blank? || ends_at.blank? || ends_at > starts_at

    errors.add(:ends_at, "は開始日時より後にしてください")
  end
end

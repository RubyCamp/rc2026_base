class Availability < ApplicationRecord
  belongs_to :staff_member

  enum :status, { available: "available", unavailable: "unavailable" }, validate: true

  validates :starts_at, :ends_at, presence: true
  validate :ends_at_after_starts_at

  def self.for_staff(staff_member_id:)
    where(staff_member_id:).order(:starts_at)
  end

  def self.register_or_update!(attributes:)
    identity = attributes.slice(:staff_member, :staff_member_id, :starts_at)

    find_or_initialize_by(identity).tap do |availability|
      availability.assign_attributes(attributes)
      availability.save!
    end
  end

  def self.remove!(id:)
    find(id).tap(&:destroy!)
  end

  private

  def ends_at_after_starts_at
    return if starts_at.blank? || ends_at.blank? || ends_at > starts_at

    errors.add(:ends_at, "は開始日時より後にしてください")
  end
end

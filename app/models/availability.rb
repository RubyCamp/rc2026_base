class Availability < ApplicationRecord
  belongs_to :staff_member

  enum :status, { available: "available", unavailable: "unavailable" }, validate: true

  validates :starts_at, :ends_at, presence: true
  validate :ends_at_after_starts_at

  def self.for_staff(staff_member_id:)
    where(staff_member_id:).order(:starts_at)
  end

  def self.register_or_update!(attributes:)
  identity = attributes.slice(
    :staff_member,
    :staff_member_id,
    :starts_at
  )

  transaction do
    find_or_initialize_by(identity).tap do |availability|
      action_type =
        availability.new_record? ? :created : :updated

      availability.assign_attributes(attributes)
      availability.save!

      next unless availability.saved_changes.except("updated_at").any?

      ChangeEvent.record!(
        target_type: :availability,
        target_id: availability.id,
        action_type: action_type,
        summary: "#{availability.staff_member.name}さんの勤務可否を" \
                 "#{action_type == :created ? '登録' : '更新'}しました"
      )
    end
  end
end

def self.remove!(id:)
  transaction do
    find(id).tap do |availability|
      target_id = availability.id
      staff_name = availability.staff_member.name

      availability.destroy!

      ChangeEvent.record!(
        target_type: :availability,
        target_id: target_id,
        action_type: :deleted,
        summary: "#{staff_name}さんの勤務可否を削除しました"
      )
    end
  end
end

  private

  def ends_at_after_starts_at
    return if starts_at.blank? || ends_at.blank? || ends_at > starts_at

    errors.add(:ends_at, "は開始日時より後にしてください")
  end
end

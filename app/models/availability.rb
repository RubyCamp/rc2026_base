class Availability < ApplicationRecord
  belongs_to :staff_member

  # team6のフォームが日付を独立して扱うための仮想属性。DB schemaは基盤のまま維持する。
  attr_accessor :work_date

  enum :status, { available: "available", unavailable: "unavailable" }, validate: true

  validates :starts_at, :ends_at, presence: true
  validate :overlapping_shift_for_staff_member
  validate :ends_at_after_starts_at

  def self.for_staff(staff_member_id:)
    where(staff_member_id:).order(:starts_at)
  end

  def self.register_or_update!(attributes:)
    attributes = attributes.to_h.symbolize_keys
    identity = {
      staff_member_id: attributes[:staff_member_id] || attributes[:staff_member]&.id,
      starts_at: attributes[:starts_at]
    }

    transaction do
      find_or_initialize_by(identity).tap do |availability|
        action_type = availability.new_record? ? :created : :updated
        availability.assign_attributes(attributes)
        availability.save!

        record_change!(availability, action_type) if business_changes?(availability)
      end
    end
  end

  # 開始時刻を含むフォーム編集を同じレコードへ適用する。
  def self.update_details!(id:, attributes:)
    transaction do
      find(id).tap do |availability|
        availability.assign_attributes(attributes.to_h.symbolize_keys)
        availability.save!

        record_change!(availability, :updated) if business_changes?(availability)
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

  def self.business_changes?(record)
    record.saved_changes.except("updated_at").any?
  end

  def self.record_change!(availability, action_type)
    ChangeEvent.record!(
      target_type: :availability,
      target_id: availability.id,
      action_type: action_type,
      summary: "#{availability.staff_member.name}さんの勤務可否を" \
               "#{action_type == :created ? '登録' : '更新'}しました"
    )
  end

  private_class_method :business_changes?, :record_change!

  private

  def overlapping_shift_for_staff_member
    return if staff_member_id.blank? || starts_at.blank? || ends_at.blank?

    duplicate_exists = self.class
      .where(staff_member_id: staff_member_id)
      .where("starts_at < ? AND ends_at > ?", ends_at, starts_at)
      .where.not(id: id)
      .exists?

    errors.add(:starts_at, "は同じスタッフの同じ時間帯に登録できません") if duplicate_exists
  end

  def ends_at_after_starts_at
    return if starts_at.blank? || ends_at.blank? || ends_at > starts_at

    errors.add(:ends_at, "は開始日時より後にしてください")
  end
end

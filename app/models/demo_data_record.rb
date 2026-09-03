class DemoDataRecord < ApplicationRecord
  belongs_to :demo_data_batch
  belongs_to :record, polymorphic: true, optional: true

  RECORD_TYPES = %w[
    Business
    Skill
    StaffMember
    StaffSkill
    Availability
    WorkRequest
    Assignment
    ChangeEvent
  ].freeze

  validates :record_type, inclusion: { in: RECORD_TYPES }
  validates :record_id, numericality: { only_integer: true, greater_than: 0 }
  validates :record_type, uniqueness: { scope: %i[record_id demo_data_batch_id] }

  scope :for_type, ->(record_type) { where(record_type:) }
end

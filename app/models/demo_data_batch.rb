class DemoDataBatch < ApplicationRecord
  has_many :demo_data_records, dependent: :delete_all

  enum :status, { active: "active", cleaned: "cleaned" }, validate: true

  validates :identifier, :label, presence: true
  validates :identifier, uniqueness: true
  validates :seed, numericality: { only_integer: true }

  scope :latest_first, -> { order(created_at: :desc, id: :desc) }

  def track!(record)
    demo_data_records.create!(
      record_type: record.class.base_class.name,
      record_id: record.id
    )
  end

  def tracked_ids(record_type)
    demo_data_records.where(record_type: record_type).select(:record_id)
  end
end

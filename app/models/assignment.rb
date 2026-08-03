class Assignment < ApplicationRecord
  belongs_to :work_request
  belongs_to :staff_member

  enum :status, { draft: "draft", confirmed: "confirmed" }, validate: true

  validates :staff_member_id,
            uniqueness: {
              scope: :work_request_id
            }

  def self.for_work_request(work_request_id:)
    includes(:staff_member).where(work_request_id:).order(:created_at)
  end

  def self.draft_for_confirmation
    includes(:staff_member, work_request: :business)
      .where(status: :draft)
      .order("work_requests.starts_at", :created_at)
  end

  def self.assign!(work_request_id:, staff_member_id:)
    create!(work_request_id:, staff_member_id:, status: :draft)
  end

  def self.confirm!(id:)
    find(id).tap(&:confirmed!)
  end

  def self.unassign!(id:)
    find(id).tap(&:destroy!)
  end
end

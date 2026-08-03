class Assignment < ApplicationRecord
  belongs_to :work_request
  belongs_to :staff_member

  enum :status, { draft: "draft", confirmed: "confirmed" }, validate: true

  validates :staff_member_id,
            uniqueness: {
              scope: :work_request_id
            }
end

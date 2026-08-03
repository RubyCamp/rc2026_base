class Business < ApplicationRecord
  has_many :work_requests, dependent: :restrict_with_error

  validates :name, :contact_name, :contact_phone, presence: true
end

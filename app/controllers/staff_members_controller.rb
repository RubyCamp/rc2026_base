class StaffMembersController < ApplicationController
  def index
    @staff_members = StaffMember
      .includes(:skills, :availabilities)
      .order(:name)
  end
end

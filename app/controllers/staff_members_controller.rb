class StaffMembersController < ApplicationController
  def index
    @staff_members = StaffMember
      .includes(
        :skills,
        :availabilities,
        assignments: { work_request: [ :business, :assignments ] }
      )
      .order(:name)
      .to_a
    @assignment_judgments = Assignment.judgments_for(
      @staff_members.flat_map(&:assignments),
      staff_members: @staff_members
    )
  end
end

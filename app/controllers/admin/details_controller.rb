module Admin
  class DetailsController < ApplicationController
    def show
      @work_request = WorkRequest
        .includes(:business, :required_skill, assignments: :staff_member)
        .find(params[:id])
    end
  end
end

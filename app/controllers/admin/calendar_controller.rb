module Admin
  class CalendarController < ApplicationController
    def index
      @month = parse_month(params[:month]) || Date.current.beginning_of_month
      @businesses = Business.for_selection
      @work_requests = WorkRequest
        .for_list
        .where(starts_at: @month..@month.end_of_month.end_of_day)
    end
  end
end

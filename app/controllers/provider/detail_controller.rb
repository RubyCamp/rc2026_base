module Provider
  class DetailController < ApplicationController
    def show
      @business = Business.find_by(id: session[:business_id])
      @work_requests = WorkRequest
        .for_list
        .where(business_id: session[:business_id])
    end
  end
end

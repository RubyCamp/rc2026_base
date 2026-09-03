class HomeController < ApplicationController
  def index
    case session[:role]
    when "admin"
      redirect_to admin_calendar_path
    when "business"
      redirect_to provider_detail_path
    else
      redirect_to login_path
    end
  end
end

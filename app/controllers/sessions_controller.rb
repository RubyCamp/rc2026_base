class SessionsController < ApplicationController
  def new
    @businesses = Business.for_selection
    render :login
  end

  def create
    session[:role] = params[:role]
    session[:business_id] = params[:role] == "business" ? params[:business_id] : nil
    redirect_to login_destination
  end

  def destroy
    session.delete(:role)
    session.delete(:business_id)
    redirect_to root_path
  end

  private

  def login_destination
    case session[:role]
    when "admin"
      admin_calendar_path
    when "business"
      provider_detail_path
    else
      guide_path
    end
  end
end

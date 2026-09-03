class SessionsController < ApplicationController
  def new
    @businesses = Business.for_selection
    render :login
  end

  def create
    session[:role] = params[:role]
    session[:business_id] = params[:role] == "business" ? params[:business_id] : nil
    redirect_to root_path
  end

  def destroy
    session.delete(:role)
    session.delete(:business_id)
    redirect_to root_path
  end
end

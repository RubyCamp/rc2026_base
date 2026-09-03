class TutorialsController < ApplicationController
  def index
    @profiles = TutorialProfile.published

    @profiles = @profiles.select { |profile| profile.category == params[:category] } if params[:category].present?
    @profiles = @profiles.select { |profile| profile.matches?(params[:q]) } if params[:q].present?
    @profiles = @profiles.sort_by(&:name)
  end

  def debug
    @profile = TutorialProfile.find(1)
  end

  def show
    @profile = TutorialProfile.find(params[:id])
  end
end

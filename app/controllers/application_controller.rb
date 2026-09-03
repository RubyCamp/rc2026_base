class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper ApplicationHelper
  helper WorkRequestsHelper

  private

  def parse_month(value)
    return if value.blank?

    Date.strptime(value, "%Y-%m").beginning_of_month
  rescue ArgumentError
    nil
  end
end

class ChangeEventsController < ApplicationController
  def index
    @change_events = ChangeEvent.recent
    @change_events = @change_events.where(review_status: params[:review_status]) if params[:review_status].present?
  end

  def update
    ChangeEvent.toggle_reviewed!(id: params[:id])

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to change_events_path, notice: "変更記録の確認状況を変更しました。" }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to change_events_path, alert: "変更記録が見つかりませんでした。"
  end
end

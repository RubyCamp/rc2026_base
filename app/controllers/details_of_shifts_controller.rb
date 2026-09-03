class DetailsOfShiftsController < ApplicationController
  def index
    @work_requests = WorkRequest
      .includes(:business, :required_skill, assignments: :staff_member)
      .order(:starts_at)

    if params[:keyword].present?
      keyword = "%#{ActiveRecord::Base.sanitize_sql_like(params[:keyword])}%"
      @work_requests = @work_requests
        .joins(:business, :required_skill)
        .where(
          "work_requests.title ILIKE :keyword " \
          "OR businesses.name ILIKE :keyword " \
          "OR skills.name ILIKE :keyword",
          keyword: keyword
        )
    end

    @work_requests = case params[:shortage]
    when "yes"
      @work_requests.select { |work_request| work_request.staffing_shortage_count.positive? }
    when "no"
      @work_requests.select { |work_request| work_request.staffing_shortage_count.zero? }
    else
      @work_requests
    end
  end

  def show
    @work_request = WorkRequest
      .includes(:business, :required_skill, assignments: :staff_member)
      .find(params[:id])
    @staff_members = StaffMember.available_for(work_request_id: @work_request.id)
  end

  def edit
    @work_request = WorkRequest.find(params[:id])
  end

  def update
    @work_request = WorkRequest.update_details!(
      id: params[:id],
      attributes: work_request_params
    )
    redirect_to details_of_shift_path(@work_request), notice: "勤務依頼の備考を更新しました。"
  rescue ActiveRecord::RecordInvalid => error
    raise unless error.record.is_a?(WorkRequest)

    @work_request = error.record
    render :edit, status: :unprocessable_content
  rescue ActiveRecord::RecordNotFound
    redirect_to details_of_shifts_path, alert: "更新する勤務依頼が見つかりませんでした。"
  end

  private

  def work_request_params
    params.expect(work_request: [ :notes ])
  end
end

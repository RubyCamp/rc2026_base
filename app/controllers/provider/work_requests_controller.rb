module Provider
  class WorkRequestsController < ApplicationController
    before_action :set_work_request, only: %i[show edit update]

    def new
      @work_request = WorkRequest.new
      @skills = Skill.for_selection
    end

    def create
      @work_request = WorkRequest.register!(
        attributes: work_request_params.merge(business_id: session[:business_id])
      )

      redirect_to provider_detail_path, notice: "勤務依頼を作成しました。"
    rescue ActiveRecord::RecordInvalid => error
      raise unless error.record.is_a?(WorkRequest)

      @work_request = error.record
      @skills = Skill.for_selection
      render :new, status: :unprocessable_content
    end

    def show
    end

    def edit
      @skills = Skill.for_selection
    end

    def update
      @work_request = WorkRequest.update_details!(
        id: params[:id],
        attributes: provider_work_request_params
      )

      redirect_to provider_work_request_path(@work_request), notice: "勤務依頼を更新しました。"
    rescue ActiveRecord::RecordInvalid => error
      raise unless error.record.is_a?(WorkRequest)

      @work_request = error.record
      @skills = Skill.for_selection
      render :edit, status: :unprocessable_content
    rescue ActiveRecord::RecordNotFound
      redirect_to provider_detail_path, alert: "更新する勤務依頼が見つかりませんでした。"
    end

    private

    def set_work_request
      @work_request = WorkRequest
        .includes(:business, :required_skill, assignments: :staff_member)
        .find_by(id: params[:id], business_id: session[:business_id])

      return if @work_request

      redirect_to provider_detail_path, alert: "勤務依頼が見つかりませんでした。"
    end

    def provider_work_request_params
      params.expect(work_request: [
        :required_skill_id,
        :title,
        :starts_at,
        :ends_at,
        :required_staff_count,
        :status,
        :notes
      ])
    end

    def work_request_params
      params.expect(work_request: [
        :required_skill_id,
        :title,
        :starts_at,
        :ends_at,
        :required_staff_count,
        :status,
        :notes
      ])
    end
  end
end

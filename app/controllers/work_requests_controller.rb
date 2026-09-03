class WorkRequestsController < ApplicationController
  def index
    @work_requests = WorkRequest
      .includes(:business, :required_skill, assignments: :staff_member)
      .order(:starts_at)
  end

  def show
    @work_request = WorkRequest
      .includes(:business, :required_skill, assignments: :staff_member)
      .find(params[:id])

    assigned_staff_ids = Assignment
      .where(work_request_id: @work_request.id)
      .select(:staff_member_id)

    @assignable_staff_members = StaffMember
      .for_assignment
      .includes(:skills)
      .where.not(id: assigned_staff_ids)
  end

  def edit
    @work_request = WorkRequest.find(params[:id])
  end

  def update
    @work_request = WorkRequest.update_details!(
      id: params[:id],
      attributes: work_request_params
    )

    redirect_to @work_request, notice: "勤務依頼の備考を更新しました。"
  rescue ActiveRecord::RecordInvalid => error
    raise unless error.record.is_a?(WorkRequest)

    @work_request = error.record
    render :edit, status: :unprocessable_content
  rescue ActiveRecord::RecordNotFound
    redirect_to work_requests_path, alert: "更新する勤務依頼が見つかりませんでした。"
  end

  # team1の手動仮割当。候補の警告表示は詳細画面と評価画面で行い、
  # ここでは既存の操作感を維持して仮割当そのものを受け付ける。
  def assign
    assignment = Assignment.assign!(
      work_request_id: params[:id],
      staff_member_id: params.expect(:staff_member_id)
    )

    redirect_to assignment.work_request,
      notice: "#{assignment.staff_member.name}さんを仮割り当てしました。"
  rescue ActionController::ParameterMissing
    redirect_to work_request_path(params[:id]),
      alert: "スタッフを選択してください。"
  rescue ActiveRecord::RecordInvalid => error
    redirect_to work_request_path(params[:id]),
      alert: error.record.errors.full_messages.to_sentence
  rescue ActiveRecord::RecordNotFound
    redirect_to work_requests_path,
      alert: "割り当てる勤務依頼が見つかりませんでした。"
  end

  def unassign
    assignment = Assignment.find_by!(
      id: params.expect(:assignment_id),
      work_request_id: params[:id]
    )

    unless assignment.draft?
      redirect_to work_request_path(params[:id]),
        alert: "仮割り当てだけキャンセルできます。"
      return
    end

    staff_name = assignment.staff_member.name
    Assignment.unassign!(id: assignment.id)
    redirect_to work_request_path(params[:id]),
      notice: "#{staff_name}さんの仮割り当てをキャンセルしました。"
  rescue ActionController::ParameterMissing, ActiveRecord::RecordNotFound
    redirect_to work_request_path(params[:id]),
      alert: "キャンセルする仮割り当てが見つかりませんでした。"
  rescue ActiveRecord::RecordNotDestroyed => error
    redirect_to work_request_path(params[:id]),
      alert: error.record.errors.full_messages.to_sentence
  end

  def confirm
    work_request = WorkRequest.confirm!(id: params[:id])
    redirect_to work_request,
      notice: "受付を終了し、勤務依頼を確定しました。"
  rescue ActiveRecord::RecordInvalid => error
    redirect_to work_request_path(params[:id]),
      alert: error.record.errors.full_messages.to_sentence
  rescue ActiveRecord::RecordNotFound
    redirect_to work_requests_path,
      alert: "確定する勤務依頼が見つかりませんでした。"
  end

  # team5の自動仮割当。DBを書き換えるためPOSTでのみ公開する。
  def draft
    @work_request = WorkRequest.find(params[:id])

    @staff_members = StaffMember
      .available_for(work_request_id: @work_request.id)
      .limit(@work_request.staffing_shortage_count)

    @staff_members.each do |staff_member|
      break if @work_request.reload.staffing_sufficient?

      Assignment.assign!(
        work_request_id: @work_request.id,
        staff_member_id: staff_member.id
      )
    end

    @staffing_shortage_count = @work_request.reload.staffing_shortage_count

    respond_to do |format|
      format.turbo_stream do
        if @staffing_shortage_count.positive?
          render :draft
        else
          redirect_to @work_request, status: :see_other
        end
      end

      format.html { redirect_to @work_request }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to work_requests_path, alert: "仮割当する勤務依頼が見つかりませんでした。"
  end

  # 仮割当全解除。確定済みの割当は業務上の確定結果なので触らない。
  def unassign_all
    @work_request = WorkRequest.find(params[:id])

    @work_request.assignments.where(status: :draft).find_each do |assignment|
      Assignment.unassign!(id: assignment.id)
    end

    redirect_to work_request_path(@work_request),
      notice: "仮割り当てを全解除しました。"
  rescue ActiveRecord::RecordNotFound
    redirect_to work_requests_path, alert: "仮割当を解除する勤務依頼が見つかりませんでした。"
  end

  def destroy_assignment
    @work_request = WorkRequest.find(params[:work_request_id])
    assignment = @work_request.assignments.find(params[:id])

    unless assignment.draft?
      respond_to do |format|
        format.turbo_stream do
          redirect_to @work_request, alert: "確定済みの割当は解除できません。"
        end
        format.html do
          redirect_to @work_request, alert: "確定済みの割当は解除できません。"
        end
      end
      return
    end

    Assignment.unassign!(id: assignment.id)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @work_request }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to work_requests_path, alert: "解除する割当が見つかりませんでした。"
  end

  def shift
    @staff_members = StaffMember
      .includes(:skills, :availabilities)
      .order(:id)

    @work_requests = WorkRequest
      .includes(:business, :required_skill, assignments: :staff_member)
      .order(:starts_at)

    @time_slot_groups, @time_slots = build_time_slots(@work_requests)
    @shift_rows = build_shift_rows(@staff_members, @work_requests, @time_slots)
  end

  def export
    shift

    rows = []
    date_row = [ "" ]

    @time_slot_groups.each do |date, slots|
      date_row << "#{date.month}/#{date.day}"
      (slots.size - 1).times { date_row << "" }
    end

    rows << date_row
    rows << [ "", *@time_slots.map { |slot| slot.strftime("%H:%M~") } ]

    @shift_rows.each do |row|
      rows << [
        row[:show_name] ? row[:staff].name : "",
        *row[:cells].map { |cell| cell[:label] }
      ]
    end

    csv_data = rows.map { |row| row.map { |value| csv_escape(value) }.join(",") }.join("\r\n")
    requested_filename = params[:filename].to_s.strip
    requested_filename = "シフト表_#{Time.current.strftime('%Y%m%d_%H%M')}" if requested_filename.empty?

    safe_filename = requested_filename.gsub(/[\\\/:*?"<>|]/, "_")
    safe_filename = safe_filename.sub(/(?:\.csv)+\z/i, "")
    safe_filename = "シフト表_#{Time.current.strftime('%Y%m%d_%H%M')}" if safe_filename.empty?

    send_data(
      "\uFEFF#{csv_data}",
      filename: "#{safe_filename}.csv",
      type: "text/csv; charset=utf-8",
      disposition: "attachment"
    )
  end

  def csv_escape(value)
    text = value.to_s
    text = "'#{text}" if text.match?(/\A[=+@\t\r]/)
    text = text.gsub('"', '""')
    text.match?(/[",\r\n]/) ? %("#{text}") : text
  end

  private

  def work_request_params
    params.expect(work_request: [ :notes ])
  end

  def build_time_slots(work_requests)
    return [ {}, [] ] if work_requests.empty?

    start_time = work_requests.map(&:starts_at).min.beginning_of_hour
    latest_end = work_requests.map(&:ends_at).max
    end_time = latest_end.beginning_of_hour
    end_time += 1.hour unless latest_end.min.zero? && latest_end.sec.zero?
    slots = (start_time...end_time).step(1.hour).to_a
    [ slots.group_by(&:to_date), slots ]
  end

  def build_shift_rows(staff_members, work_requests, time_slots)
    staff_members.flat_map do |staff_member|
      assignments = work_requests.flat_map do |work_request|
        work_request.assignments
          .select { |assignment| assignment.staff_member_id == staff_member.id }
          .map { |assignment| [ work_request, assignment ] }
      end.sort_by { |work_request, _assignment| work_request.starts_at }

      split_into_tracks(assignments).each_with_index.map do |track, index|
        cells = time_slots.map do |slot|
          occupying = track.select do |work_request, _assignment|
            work_request.starts_at <= slot && slot < work_request.ends_at
          end

          if occupying.empty?
            { state: :empty, label: nil }
          else
            work_request, assignment = occupying.first
            first_hour = work_request.starts_at.beginning_of_hour == slot
            last_hour = slot + 1.hour >= work_request.ends_at
            mark = assignment.status == "confirmed" ? "○" : "△"
            label = if first_hour && last_hour
              "#{work_request.business.name} [#{work_request.title}] #{mark}"
            elsif first_hour
              "#{work_request.business.name} [#{work_request.title}]"
            elsif last_hour
              mark
            end
            { state: assignment.status.to_sym, label: label }
          end
        end

        { staff: staff_member, cells: cells, show_name: index.zero? }
      end
    end
  end

  def split_into_tracks(assignments)
    tracks = []

    assignments.each do |work_request, assignment|
      track = tracks.find do |entries|
        entries.none? { |other_work_request, _| overlap?(other_work_request, work_request) }
      end

      if track
        track << [ work_request, assignment ]
      else
        tracks << [ [ work_request, assignment ] ]
      end
    end

    tracks.presence || [ [] ]
  end

  def overlap?(work_request_one, work_request_two)
    work_request_one.starts_at < work_request_two.ends_at &&
      work_request_two.starts_at < work_request_one.ends_at
  end
end

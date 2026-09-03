class AvailabilitiesController < ApplicationController
  def index
    @current_month = requested_month
    @staff_member_id = params[:staff_member_id].presence
    @calendar_start = @current_month.beginning_of_month - @current_month.beginning_of_month.wday.days
    calendar_end = @calendar_start + 42.days
    @calendar_days = (@calendar_start...calendar_end).to_a

    availabilities = Availability
      .includes(:staff_member)
      .where(starts_at: @calendar_start...calendar_end)
      .order(:starts_at)
    availabilities = availabilities.where(staff_member_id: @staff_member_id) if @staff_member_id
    @availabilities_by_date = availabilities.group_by { |availability| availability.starts_at.to_date }

    @staff_members = StaffMember.order(:name)
    monthly_availabilities = Availability
      .includes(:staff_member)
      .where(starts_at: @current_month...@current_month.next_month)
      .order(:starts_at)
    monthly_availabilities = monthly_availabilities.where(staff_member_id: @staff_member_id) if @staff_member_id
    @monthly_availabilities_by_staff = monthly_availabilities.group_by(&:staff_member_id)
  end

  def new
    @availability = Availability.new(status: :available)
    @availability.work_date = Date.current.iso8601
    @staff_members = StaffMember.order(:name)
  end

  def create
    @availability = Availability.register_or_update!(attributes: availability_attributes)
    redirect_to availabilities_path, notice: "勤務可否を登録しました。"
  rescue ActiveRecord::RecordInvalid => error
    raise unless error.record.is_a?(Availability)

    @availability = error.record
    @availability.work_date ||= params.dig(:availability, :work_date)
    @staff_members = StaffMember.order(:name)
    render :new, status: :unprocessable_content
  end

  def edit
    @availability = Availability.find(params[:id])
    @availability.work_date = @availability.starts_at.to_date.iso8601
    @staff_members = StaffMember.order(:name)
  end

  def update
    @availability = Availability.update_details!(
      id: params[:id],
      attributes: availability_attributes
    )
    redirect_to availabilities_path, notice: "勤務可否を更新しました。"
  rescue ActiveRecord::RecordInvalid => error
    raise unless error.record.is_a?(Availability)

    @availability = error.record
    @availability.work_date ||= params.dig(:availability, :work_date)
    @staff_members = StaffMember.order(:name)
    render :edit, status: :unprocessable_content
  rescue ActiveRecord::RecordNotFound
    redirect_to availabilities_path, alert: "更新する勤務可否が見つかりませんでした。"
  end

  def destroy
    Availability.remove!(id: params[:id])
    redirect_to availabilities_path, notice: "勤務可否を削除しました。"
  rescue ActiveRecord::RecordNotFound
    redirect_to availabilities_path, alert: "削除する勤務可否が見つかりませんでした。"
  end

  private

  def requested_month
    Date.strptime(params[:month].to_s, "%Y-%m").beginning_of_month
  rescue ArgumentError, Date::Error
    Date.current.beginning_of_month
  end

  def availability_attributes
    raw = params.expect(availability: [
      :staff_member_id,
      :work_date,
      :starts_at,
      :ends_at,
      :status,
      :notes
    ]).to_h.symbolize_keys

    work_date = Date.iso8601(raw.delete(:work_date).to_s)
    starts_at = Time.zone.parse("#{work_date} #{raw.delete(:starts_at)}")
    ends_at = Time.zone.parse("#{work_date} #{raw.delete(:ends_at)}")
    raw.merge(starts_at: starts_at, ends_at: ends_at)
  rescue ArgumentError, TypeError, Date::Error
    raw.merge(starts_at: nil, ends_at: nil)
  end
end

class Assignment < ApplicationRecord
  belongs_to :work_request
  belongs_to :staff_member

  enum :status, { draft: "draft", confirmed: "confirmed" }, validate: true

  validates :staff_member_id,
            uniqueness: {
              scope: :work_request_id
            }

  def self.for_work_request(work_request_id:)
    includes(:staff_member).where(work_request_id:).order(:created_at)
  end

  def self.draft_for_confirmation
    includes(
      { staff_member: { staff_skills: :skill } },
      work_request: [ :business, :required_skill ]
    )
      .where(status: :draft)
      .order("work_requests.starts_at", :created_at)
  end

  def self.judgments_for(assignments, staff_members: nil)
    assignments = assignments.to_a
    staff_members ||= assignments.map(&:staff_member).uniq
    staff_by_id = staff_members.index_by(&:id)
    staff_skill_ids = staff_members.to_h do |staff_member|
      [ staff_member.id, staff_member.staff_skills.to_h { |staff_skill| [ staff_skill.skill_id, true ] } ]
    end
    assignments_by_staff = staff_members.to_h do |staff_member|
      [ staff_member.id, staff_member.assignments.to_a ]
    end
    assignment_counts = assignment_counts_by_work_request(assignments_by_staff)
    time_conflict_ids = time_conflict_ids_by_staff(assignments_by_staff)

    assignments_by_staff.values.flatten.uniq.each_with_object({}) do |assignment, judgments|
      work_request = assignment.work_request
      staff_member = staff_by_id[assignment.staff_member_id]
      skilled = staff_member&.active? && staff_skill_ids
        .fetch(assignment.staff_member_id, {})
        .key?(work_request.required_skill_id)
      staffing_shortage = assignment_counts.fetch(work_request.id, 0) < work_request.required_staff_count

      judgments[assignment.id] = {
        skill_missing: !skilled,
        staffing_shortage: staffing_shortage,
        time_conflict: time_conflict_ids.key?(assignment.id)
      }
    end
  end

  def self.assignment_counts_by_work_request(assignments_by_staff)
    work_request_ids = assignments_by_staff.values.flatten.map(&:work_request_id).compact.uniq
    return {} if work_request_ids.empty?

    WorkRequest
      .where(id: work_request_ids)
      .left_joins(:assignments)
      .group(:id)
      .count("assignments.id")
  end
  private_class_method :assignment_counts_by_work_request

  def self.time_conflict_ids_by_staff(assignments_by_staff)
    assignments_by_staff.values.each_with_object({}) do |staff_assignments, conflict_ids|
      active_assignments = staff_assignments
        .select { |assignment| !assignment.work_request.cancelled? }
        .sort_by { |assignment| assignment.work_request.starts_at }

      previous_max_end = nil
      active_assignments.each do |assignment|
        work_request = assignment.work_request
        conflict_ids[assignment.id] = true if previous_max_end && previous_max_end > work_request.starts_at
        previous_max_end = [ previous_max_end, work_request.ends_at ].compact.max
      end

      active_assignments.each_cons(2) do |assignment, next_assignment|
        next unless next_assignment.work_request.starts_at < assignment.work_request.ends_at

        conflict_ids[assignment.id] = true
        conflict_ids[next_assignment.id] = true
      end
    end
  end
  private_class_method :time_conflict_ids_by_staff

  def self.overlapping_for(id:)
    assignment = find(id)
    work_request = assignment.work_request
    return none if work_request.cancelled?

    joins(:work_request)
      .where(staff_member_id: assignment.staff_member_id)
      .where.not(id: id)
      .where.not(work_requests: { status: :cancelled })
      .where(
        "work_requests.starts_at < :target_ends_at " \
        "AND work_requests.ends_at > :target_starts_at",
        target_ends_at: work_request.ends_at,
        target_starts_at: work_request.starts_at
      )
      .order("work_requests.starts_at", :created_at)
  end

  def self.time_conflict?(id:)
    overlapping_for(id: id).exists?
  end

  def self.time_conflict_for?(work_request_id:, staff_member_id:)
    work_request = WorkRequest.find(work_request_id)
    return false if work_request.cancelled?

    joins(:work_request)
      .where(staff_member_id: staff_member_id)
      .where.not(work_request_id: work_request_id)
      .where.not(work_requests: { status: :cancelled })
      .where(
        "work_requests.starts_at < :target_ends_at " \
        "AND work_requests.ends_at > :target_starts_at",
        target_ends_at: work_request.ends_at,
        target_starts_at: work_request.starts_at
      )
      .exists?
  end

  def self.assign!(work_request_id:, staff_member_id:)
    transaction do
      create!(
        work_request_id: work_request_id,
        staff_member_id: staff_member_id,
        status: :draft
      ).tap do |assignment|
        ChangeEvent.record!(
          target_type: :assignment,
          target_id: assignment.id,
          action_type: :assigned,
          summary: "#{assignment.staff_member.name}さんを" \
                   "勤務依頼「#{assignment.work_request.title}」へ" \
                   "仮割当しました"
        )
      end
    end
  end

  def self.confirm!(id:)
    transaction do
      find(id).tap do |assignment|
        assignment.confirmed!

        next unless assignment.saved_changes.except("updated_at").any?

        ChangeEvent.record!(
          target_type: :assignment,
          target_id: assignment.id,
          action_type: :confirmed,
          summary: "#{assignment.staff_member.name}さんの" \
                   "勤務依頼「#{assignment.work_request.title}」への" \
                   "割当を確定しました"
        )
      end
    end
  end

  def self.unconfirm!(id:)
    transaction do
      find(id).tap do |assignment|
        assignment.draft!

        next unless assignment.saved_changes.except("updated_at").any?

        ChangeEvent.record!(
          target_type: :assignment,
          target_id: assignment.id,
          action_type: :updated,
          summary: "#{assignment.staff_member.name}さんの" \
                   "勤務依頼「#{assignment.work_request.title}」への" \
                   "割当を未確定に戻しました"
        )
      end
    end
  end

  def self.unassign!(id:)
    transaction do
      find(id).tap do |assignment|
        target_id = assignment.id
        staff_name = assignment.staff_member.name
        work_request_title = assignment.work_request.title
        assignment.destroy!

        ChangeEvent.record!(
          target_type: :assignment,
          target_id: target_id,
          action_type: :unassigned,
          summary: "#{staff_name}さんの" \
                   "勤務依頼「#{work_request_title}」への" \
                   "割当を解除しました"
        )
      end
    end
  end
end

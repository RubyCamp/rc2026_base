class ChangeEvent < ApplicationRecord
  enum :target_type,
       {
         work_request: "work_request",
         availability: "availability",
         assignment: "assignment"
       },
       prefix: true,
       validate: true

  enum :action_type,
       {
         created: "created",
         updated: "updated",
         cancelled: "cancelled",
         deleted: "deleted",
         assigned: "assigned",
         confirmed: "confirmed",
         unassigned: "unassigned"
       },
       prefix: true,
       validate: true

  enum :review_status,
       {
         pending: "pending",
         reviewed: "reviewed"
       },
       prefix: true,
       validate: true

  enum :source,
       {
         operation: "operation",
         seed: "seed",
         debug: "debug"
       },
       prefix: true,
       validate: true

  validates :summary, :occurred_at, presence: true

  def self.recent
    order(occurred_at: :desc, id: :desc)
  end

  def self.pending_review
    where(review_status: :pending).recent
  end

  def self.pending_count
    pending_review.count
  end

  def self.record!(
    target_type:,
    target_id:,
    action_type:,
    summary:,
    occurred_at: Time.current,
    source: :operation,
    review_status: :pending,
    reviewed_at: nil
  )
    create!(
      target_type: target_type,
      target_id: target_id,
      action_type: action_type,
      summary: summary,
      occurred_at: occurred_at,
      source: source,
      review_status: review_status,
      reviewed_at: reviewed_at
    )
  end

  def self.mark_reviewed!(id:)
    find(id).tap do |change_event|
      next if change_event.review_status_reviewed?

      change_event.update!(
        review_status: :reviewed,
        reviewed_at: Time.current
      )
    end
  end

  def self.remove_debug!(id:)
    find(id).tap do |change_event|
      unless debug_enabled? && change_event.source_debug?
        message = "開発用の変更記録だけ削除できます"
        change_event.errors.add(:base, message)

        raise ActiveRecord::RecordNotDestroyed.new(
          message,
          change_event
        )
      end

      change_event.destroy!
    end
  end

  def self.debug_enabled?
    Rails.env.development? &&
      ENV["ENABLE_CHANGE_EVENT_DEBUG"] == "true"
  end
end

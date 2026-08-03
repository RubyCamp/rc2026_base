class CreateChangeEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :change_events do |t|
      t.string :target_type, null: false
      t.bigint :target_id
      t.string :action_type, null: false
      t.text :summary, null: false
      t.datetime :occurred_at, null: false
      t.string :review_status, null: false, default: "pending"
      t.datetime :reviewed_at
      t.string :source, null: false, default: "operation"

      t.timestamps
    end

    add_index :change_events, %i[occurred_at id]
    add_index :change_events, :review_status
    add_index :change_events, %i[target_type target_id]
    add_index :change_events, :source

    add_check_constraint :change_events,
                         "target_type IN ('work_request', 'availability', 'assignment')",
                         name: "change_events_target_type_check"

    add_check_constraint :change_events,
                         "action_type IN ('created', 'updated', 'cancelled', 'deleted', 'assigned', 'confirmed', 'unassigned')",
                         name: "change_events_action_type_check"

    add_check_constraint :change_events,
                         "review_status IN ('pending', 'reviewed')",
                         name: "change_events_review_status_check"

    add_check_constraint :change_events,
                         "source IN ('operation', 'seed', 'debug')",
                         name: "change_events_source_check"
  end
end

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_03_172749) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "assignments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "notes"
    t.bigint "staff_member_id", null: false
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.bigint "work_request_id", null: false
    t.index ["staff_member_id"], name: "index_assignments_on_staff_member_id"
    t.index ["status"], name: "index_assignments_on_status"
    t.index ["work_request_id", "staff_member_id"], name: "index_assignments_on_work_request_id_and_staff_member_id", unique: true
    t.index ["work_request_id"], name: "index_assignments_on_work_request_id"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying::text, 'confirmed'::character varying::text])", name: "assignments_status_check"
  end

  create_table "availabilities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "ends_at", null: false
    t.text "notes"
    t.bigint "staff_member_id", null: false
    t.datetime "starts_at", null: false
    t.string "status", default: "available", null: false
    t.datetime "updated_at", null: false
    t.index ["staff_member_id", "starts_at"], name: "index_availabilities_on_staff_member_id_and_starts_at"
    t.index ["staff_member_id"], name: "index_availabilities_on_staff_member_id"
    t.check_constraint "ends_at > starts_at", name: "availabilities_time_range_check"
    t.check_constraint "status::text = ANY (ARRAY['available'::character varying::text, 'unavailable'::character varying::text])", name: "availabilities_status_check"
  end

  create_table "businesses", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "contact_name", null: false
    t.string "contact_phone", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.text "notes"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_businesses_on_name"
  end

  create_table "change_events", force: :cascade do |t|
    t.string "action_type", null: false
    t.datetime "created_at", null: false
    t.datetime "occurred_at", null: false
    t.string "review_status", default: "pending", null: false
    t.datetime "reviewed_at"
    t.string "source", default: "operation", null: false
    t.text "summary", null: false
    t.bigint "target_id"
    t.string "target_type", null: false
    t.datetime "updated_at", null: false
    t.index ["occurred_at", "id"], name: "index_change_events_on_occurred_at_and_id"
    t.index ["review_status"], name: "index_change_events_on_review_status"
    t.index ["source"], name: "index_change_events_on_source"
    t.index ["target_type", "target_id"], name: "index_change_events_on_target_type_and_target_id"
    t.check_constraint "action_type::text = ANY (ARRAY['created'::character varying::text, 'updated'::character varying::text, 'cancelled'::character varying::text, 'deleted'::character varying::text, 'assigned'::character varying::text, 'confirmed'::character varying::text, 'unassigned'::character varying::text])", name: "change_events_action_type_check"
    t.check_constraint "review_status::text = ANY (ARRAY['pending'::character varying::text, 'reviewed'::character varying::text])", name: "change_events_review_status_check"
    t.check_constraint "source::text = ANY (ARRAY['operation'::character varying::text, 'seed'::character varying::text, 'debug'::character varying::text])", name: "change_events_source_check"
    t.check_constraint "target_type::text = ANY (ARRAY['work_request'::character varying::text, 'availability'::character varying::text, 'assignment'::character varying::text])", name: "change_events_target_type_check"
  end

  create_table "skills", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_skills_on_code", unique: true
  end

  create_table "staff_members", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "employment_status", default: "active", null: false
    t.string "name", null: false
    t.text "notes"
    t.datetime "updated_at", null: false
    t.index ["employment_status"], name: "index_staff_members_on_employment_status"
    t.index ["name"], name: "index_staff_members_on_name"
    t.check_constraint "employment_status::text = ANY (ARRAY['active'::character varying::text, 'inactive'::character varying::text])", name: "staff_members_employment_status_check"
  end

  create_table "staff_skills", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "proficiency_label", null: false
    t.bigint "skill_id", null: false
    t.bigint "staff_member_id", null: false
    t.datetime "updated_at", null: false
    t.index ["skill_id"], name: "index_staff_skills_on_skill_id"
    t.index ["staff_member_id", "skill_id"], name: "index_staff_skills_on_staff_member_id_and_skill_id", unique: true
    t.index ["staff_member_id"], name: "index_staff_skills_on_staff_member_id"
  end

  create_table "work_requests", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.datetime "created_at", null: false
    t.datetime "ends_at", null: false
    t.text "notes"
    t.bigint "required_skill_id", null: false
    t.integer "required_staff_count", null: false
    t.datetime "starts_at", null: false
    t.string "status", default: "draft", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_work_requests_on_business_id"
    t.index ["required_skill_id"], name: "index_work_requests_on_required_skill_id"
    t.index ["starts_at"], name: "index_work_requests_on_starts_at"
    t.index ["status"], name: "index_work_requests_on_status"
    t.check_constraint "ends_at > starts_at", name: "work_requests_time_range_check"
    t.check_constraint "required_staff_count > 0", name: "work_requests_required_staff_count_check"
    t.check_constraint "status::text = ANY (ARRAY['open'::character varying::text, 'draft'::character varying::text, 'confirmed'::character varying::text, 'cancelled'::character varying::text])", name: "work_requests_status_check"
  end

  add_foreign_key "assignments", "staff_members"
  add_foreign_key "assignments", "work_requests"
  add_foreign_key "availabilities", "staff_members"
  add_foreign_key "staff_skills", "skills"
  add_foreign_key "staff_skills", "staff_members"
  add_foreign_key "work_requests", "businesses"
  add_foreign_key "work_requests", "skills", column: "required_skill_id"
end

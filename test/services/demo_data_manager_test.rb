require "test_helper"

class DemoDataManagerTest < ActiveSupport::TestCase
  setup do
    DemoData::Manager.cleanup!
  end

  test "同じseedでシナリオを満たす規模のバッチを生成する" do
    batch = DemoData::Manager.generate!(seed: 20260903)
    months = DemoData::Generator.months_for(Time.zone.today)

    assert_equal 1, DemoDataBatch.active.count
    assert_equal 20260903, batch.seed
    assert_includes (8..12), Business.where(id: batch.tracked_ids("Business")).count
    assert_includes (8..12), Skill.where(id: batch.tracked_ids("Skill")).count
    assert_includes (30..45), StaffMember.where(id: batch.tracked_ids("StaffMember")).count
    assert_operator WorkRequest.where(id: batch.tracked_ids("WorkRequest")).count,
      :>=, DemoData::Generator::MONTHLY_MINIMUMS[:work_requests] * months.length

    assert_operator WorkRequest.where(starts_at: Time.zone.today.all_day).count, :positive?
    assert_predicate Availability.available, :any?
    assert_predicate Availability.unavailable, :any?
    assert_predicate Assignment.draft, :any?
    assert_predicate Assignment.confirmed, :any?
    assert_predicate ChangeEvent.pending_review, :any?
    assert_predicate ChangeEvent.where(review_status: :reviewed), :any?

    ok = WorkRequest.find_by!(title: "評価OK・確定候補")
    overlap = WorkRequest.find_by!(title: "時間重複・評価注意")
    skill_missing = WorkRequest.find_by!(title: "スキル不足・評価注意")
    shortage = WorkRequest.find_by!(title: "人員不足・候補確認")

    assert_not Assignment.time_conflict?(id: ok.assignments.first.id)
    assert Assignment.time_conflict?(id: overlap.assignments.first.id)
    assert_not StaffMember.skilled_for(work_request_id: skill_missing.id)
      .exists?(id: skill_missing.assignments.first.staff_member_id)
    assert_operator shortage.staffing_shortage_count, :positive?
    assert_predicate StaffMember.available_for(work_request_id: ok.id), :any?

    fixed_titles = %w[
      評価OK・確定候補
      時間重複・既存シフト
      時間重複・評価注意
      スキル不足・評価注意
      人員不足・候補確認
      確定済み・シフト確認
    ]
    owned_requests = WorkRequest.where(id: batch.tracked_ids("WorkRequest"))
    assert_equal fixed_titles.length,
      owned_requests.where(title: fixed_titles, starts_at: Time.zone.today.all_month).count
    assert_predicate StaffMember.available_for(work_request_id: ok.id)
      .where(id: batch.tracked_ids("StaffMember")), :any?
    assert_predicate owned_requests.where("notes LIKE ?", "%交通%").where(starts_at: Time.zone.today.all_month), :any?

    assert_monthly_coverage(batch)
  end

  test "生成日時を基準に19か月の範囲を固定する" do
    travel_to Time.zone.local(2027, 2, 18, 10) do
      batch = DemoData::Manager.generate!(seed: 20270218)
      months = DemoData::Generator.months_for(Time.zone.today)
      start_month = months.first
      end_month = months.last

      assert_equal Date.new(2026, 8, 1), start_month
      assert_equal Date.new(2028, 2, 1), end_month
      assert_equal 19, months.length

      assert_owned_dates_within(batch, "WorkRequest", :starts_at, start_month, end_month)
      assert_owned_dates_within(batch, "Availability", :starts_at, start_month, end_month)
      assert_owned_dates_within(batch, "ChangeEvent", :occurred_at, start_month, end_month)
      assert_monthly_coverage(batch)
    end
  end

  test "複数seedでも全月の最低条件を決定的に満たす" do
    [ 101, 202 ].each do |seed|
      batch = DemoData::Manager.generate!(seed: seed)

      assert_monthly_coverage(batch)
      assert_equal 0, duplicate_owned_records(batch)
      DemoData::Manager.cleanup!
    end
  end

  test "生成データだけを所有権情報で削除し手動データを残す" do
    manual_business = Business.create!(
      name: "手動登録事業者",
      contact_name: "手動担当者",
      contact_phone: "00-0000-0000"
    )

    DemoData::Manager.generate!(seed: 1001)
    generated_counts = DemoData::Manager.summary[:demo]

    assert_operator generated_counts.values.sum, :positive?

    DemoData::Manager.cleanup!
    second_cleanup = DemoData::Manager.cleanup!

    assert_nil second_cleanup
    assert_equal 0, DemoDataBatch.count
    assert_equal 0, DemoDataRecord.count
    assert_equal 0, DemoData::Manager.summary[:demo].values.sum
    assert_predicate manual_business.reload, :persisted?
  end

  test "resetは既存の生成分だけを入れ替え繰り返しても一つの基準バッチになる" do
    first = DemoData::Manager.generate!(seed: 2001)
    second = DemoData::Manager.reset!(seed: 2002)

    assert_not_equal first.seed, second.seed
    assert_equal 1, DemoDataBatch.active.count
    assert_equal 1, DemoDataBatch.count
    assert_equal DemoDataRecord.count, second.demo_data_records.count

    DemoData::Manager.reset!(seed: 2002)
    assert_equal 1, DemoDataBatch.count
    assert_equal 1, DemoDataBatch.active.count
  end

  test "シードを固定すると表示用の名前とシナリオが再現する" do
    DemoData::Manager.generate!(seed: 5001)
    first_snapshot = [
      Business.order(:id).pluck(:name),
      StaffMember.order(:id).pluck(:name),
      WorkRequest.order(:id).pluck(:title, :required_staff_count, :status)
    ]

    DemoData::Manager.cleanup!
    DemoData::Manager.generate!(seed: 5001)
    second_snapshot = [
      Business.order(:id).pluck(:name),
      StaffMember.order(:id).pluck(:name),
      WorkRequest.order(:id).pluck(:title, :required_staff_count, :status)
    ]

    assert_equal first_snapshot, second_snapshot
  end

  test "所有権レコードは生成バッチと各レコードを一意に結び付ける" do
    batch = DemoData::Manager.generate!(seed: 3001)

    assert_equal batch.demo_data_records.count,
      DemoDataRecord.where(demo_data_batch: batch).distinct.count
    assert_equal DemoDataRecord.count,
      DemoDataRecord.select(:record_type, :record_id).distinct.count
  end

  test "生成親を手動データが参照している場合は親を残す" do
    batch = DemoData::Manager.generate!(seed: 6001)
    business = Business.find(batch.tracked_ids("Business").pick(:record_id))
    skill = Skill.find(batch.tracked_ids("Skill").pick(:record_id))
    manual_request = WorkRequest.create!(
      business: business,
      required_skill: skill,
      title: "手動で追加した依頼",
      starts_at: Time.zone.today.noon,
      ends_at: Time.zone.today.noon + 2.hours,
      required_staff_count: 1,
      status: :open
    )

    DemoData::Manager.cleanup!

    assert_predicate manual_request.reload, :persisted?
    assert_predicate business.reload, :persisted?
    assert_predicate skill.reload, :persisted?
    assert_predicate DemoDataBatch.find(batch.id), :persisted?
  end

  private

  def assert_monthly_coverage(batch)
    months = DemoData::Generator.months_for(Time.zone.today)
    minimums = DemoData::Generator::MONTHLY_MINIMUMS

    months.each do |month|
      work_request_ids = batch.tracked_ids("WorkRequest")
      assignment_ids = batch.tracked_ids("Assignment")
      availability_ids = batch.tracked_ids("Availability")
      change_event_ids = batch.tracked_ids("ChangeEvent")

      work_requests = WorkRequest.where(id: work_request_ids, starts_at: month.all_month)
      availabilities = Availability.where(id: availability_ids, starts_at: month.all_month)
      assignments = Assignment
        .joins(:work_request)
        .where(id: assignment_ids, work_requests: { starts_at: month.all_month })
      change_events = ChangeEvent.where(id: change_event_ids, occurred_at: month.all_month)

      assert_operator work_requests.count, :>=, minimums[:work_requests], month.to_s
      assert_operator availabilities.count, :>=, minimums[:availabilities], month.to_s
      assert_operator assignments.draft.count, :>=, minimums[:draft_assignments], month.to_s
      assert_operator assignments.confirmed.count, :>=, minimums[:confirmed_assignments], month.to_s
      assert_operator change_events.count, :>=, minimums[:change_events], month.to_s
    end
  end

  def assert_owned_dates_within(batch, record_type, attribute, start_month, end_month)
    model = DemoData::Manager::TRACKED_TYPES.fetch(record_type)
    lower_bound = start_month.beginning_of_month.beginning_of_day
    upper_bound = end_month.end_of_month.end_of_day
    dates = model.where(id: batch.tracked_ids(record_type)).pluck(attribute)

    assert_operator dates.min, :>=, lower_bound
    assert_operator dates.max, :<=, upper_bound
  end

  def duplicate_owned_records(batch)
    batch.demo_data_records
      .group(:record_type, :record_id)
      .having("COUNT(*) > 1")
      .count
      .length
  end
end

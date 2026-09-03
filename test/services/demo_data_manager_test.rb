require "test_helper"

class DemoDataManagerTest < ActiveSupport::TestCase
  setup do
    DemoData::Manager.cleanup!
  end

  test "同じseedでシナリオを満たす規模のバッチを生成する" do
    batch = DemoData::Manager.generate!(seed: 20260903)

    assert_equal 1, DemoDataBatch.active.count
    assert_equal 20260903, batch.seed
    assert_includes (8..12), Business.where(id: batch.tracked_ids("Business")).count
    assert_includes (8..12), Skill.where(id: batch.tracked_ids("Skill")).count
    assert_includes (30..45), StaffMember.where(id: batch.tracked_ids("StaffMember")).count
    assert_includes (35..60), WorkRequest.where(id: batch.tracked_ids("WorkRequest")).count

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
end

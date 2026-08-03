require "test_helper"

class AssignmentTest < ActiveSupport::TestCase
  setup do
    business = Business.create!(
      name: "割当テスト事業者",
      contact_name: "担当者",
      contact_phone: "00-0000-0000"
    )

    skill = Skill.create!(
      code: "ASSIGNMENT_TEST_#{SecureRandom.hex(4)}",
      name: "割当テストスキル"
    )

    @work_request = WorkRequest.create!(
      business: business,
      required_skill: skill,
      title: "割当テスト依頼",
      starts_at: Time.zone.local(2026, 8, 20, 10),
      ends_at: Time.zone.local(2026, 8, 20, 12),
      required_staff_count: 1,
      status: :open
    )

    @staff_member = StaffMember.create!(
      name: "割当 テスト",
      employment_status: :active
    )
  end

  test "assign!は下書きの割当を作成して保存済みモデルを返す" do
  assignment = nil

  assert_difference("ChangeEvent.count", 1) do
    assignment = Assignment.assign!(
      work_request_id: @work_request.id,
      staff_member_id: @staff_member.id
    )
  end

  assert_predicate assignment, :persisted?
  assert_predicate assignment, :draft?
end

  test "assign!は重複割当でRecordInvalidを送出する" do
    Assignment.assign!(
      work_request_id: @work_request.id,
      staff_member_id: @staff_member.id
    )

    assert_raises ActiveRecord::RecordInvalid do
      Assignment.assign!(
        work_request_id: @work_request.id,
        staff_member_id: @staff_member.id
      )
    end
  end

  test "for_work_requestは対象依頼の割当Relationを返す" do
    assignment = Assignment.assign!(
      work_request_id: @work_request.id,
      staff_member_id: @staff_member.id
    )

    result = Assignment.for_work_request(
      work_request_id: @work_request.id
    )

    assert_kind_of ActiveRecord::Relation, result
    assert_equal [ assignment ], result.to_a
  end

  test "draft_for_confirmationは下書きの割当だけを返す" do
    draft_assignment = Assignment.assign!(
      work_request_id: @work_request.id,
      staff_member_id: @staff_member.id
    )

    confirmed_staff = StaffMember.create!(
      name: "確定 テスト",
      employment_status: :active
    )

    confirmed_assignment = Assignment.assign!(
      work_request_id: @work_request.id,
      staff_member_id: confirmed_staff.id
    )

    Assignment.confirm!(id: confirmed_assignment.id)

    result = Assignment
      .draft_for_confirmation
      .where(
        id: [
          draft_assignment.id,
          confirmed_assignment.id
        ]
      )

    assert_kind_of ActiveRecord::Relation, result
    assert_equal [ draft_assignment ], result.to_a
  end

  test "confirm!は確定した割当を返す" do
    assignment = Assignment.assign!(
      work_request_id: @work_request.id,
      staff_member_id: @staff_member.id
    )

    confirmed = Assignment.confirm!(id: assignment.id)

    assert_predicate confirmed, :confirmed?
    assert_equal assignment, confirmed
  end
  test "confirm!は確定済みの割当で変更記録を追加しない" do
  assignment = Assignment.assign!(
    work_request_id: @work_request.id,
    staff_member_id: @staff_member.id
  )

  Assignment.confirm!(id: assignment.id)

  assert_no_difference("ChangeEvent.count") do
    Assignment.confirm!(id: assignment.id)
  end
end

  test "unassign!は削除した割当を返す" do
  assignment = Assignment.assign!(
    work_request_id: @work_request.id,
    staff_member_id: @staff_member.id
  )

  removed = nil

  assert_difference("ChangeEvent.count", 1) do
    removed = Assignment.unassign!(id: assignment.id)
  end

  assert_predicate removed, :destroyed?

  assert_raises ActiveRecord::RecordNotFound do
    Assignment.find(assignment.id)
  end

  assert_includes(
    ChangeEvent.recent.first.summary,
    "割当を解除しました"
  )
end
end

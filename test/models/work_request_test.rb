require "test_helper"

class WorkRequestTest < ActiveSupport::TestCase
  setup do
    business = Business.create!(
      name: "テスト事業者",
      contact_name: "担当者",
      contact_phone: "00-0000-0000"
    )

    skill = Skill.create!(
      code: "WORK_REQUEST_TEST_#{SecureRandom.hex(4)}",
      name: "テストスキル"
    )

    @later_request = WorkRequest.create!(
      business: business,
      required_skill: skill,
      title: "後の依頼",
      starts_at: Time.zone.local(2026, 8, 2, 10),
      ends_at: Time.zone.local(2026, 8, 2, 12),
      required_staff_count: 1,
      status: :open
    )

    @earlier_request = WorkRequest.create!(
      business: business,
      required_skill: skill,
      title: "先の依頼",
      starts_at: Time.zone.local(2026, 8, 1, 10),
      ends_at: Time.zone.local(2026, 8, 1, 12),
      required_staff_count: 1,
      status: :open
    )
  end

  test "for_listは開始日時順のRelationを返す" do
    result = WorkRequest.for_list.where(
      id: [ @later_request.id, @earlier_request.id ]
    )

    assert_kind_of ActiveRecord::Relation, result
    assert_equal [ @earlier_request, @later_request ], result.to_a
  end

  test "with_assignment_detailsはfindを続けられるRelationを返す" do
    result = WorkRequest.with_assignment_details

    assert_kind_of ActiveRecord::Relation, result
    assert_equal @earlier_request, result.find(@earlier_request.id)
  end

  test "with_staffing_shortageは割当が必要人数未満の依頼を返す" do
    staff_member = StaffMember.create!(
      name: "不足確認スタッフ",
      employment_status: :active
    )

    Assignment.assign!(
      work_request_id: @earlier_request.id,
      staff_member_id: staff_member.id
    )

    result = WorkRequest.with_staffing_shortage.where(
      id: [ @earlier_request.id, @later_request.id ]
    )

    assert_kind_of ActiveRecord::Relation, result
    assert_equal [ @later_request ], result.to_a
  end

  test "人数計算は現在存在する割当だけを対象にする" do
    staff_member = StaffMember.create!(
      name: "人数確認スタッフ",
      employment_status: :active
    )

    assignment = Assignment.assign!(
      work_request_id: @earlier_request.id,
      staff_member_id: staff_member.id
    )

    assert_equal 1, @earlier_request.active_assignment_count
    assert_equal 0, @earlier_request.staffing_shortage_count
    assert_predicate @earlier_request, :staffing_sufficient?

    Assignment.unassign!(id: assignment.id)

    assert_equal 0, @earlier_request.active_assignment_count
    assert_equal 1, @earlier_request.staffing_shortage_count
    assert_not_predicate @earlier_request, :staffing_sufficient?
  end

  test "不足人数は割当が必要人数を超えても0を返す" do
    2.times do |index|
      staff_member = StaffMember.create!(
        name: "超過スタッフ#{index}",
        employment_status: :active
      )

      Assignment.assign!(
        work_request_id: @earlier_request.id,
        staff_member_id: staff_member.id
      )
    end

    assert_equal 0, @earlier_request.staffing_shortage_count
  end

  test "register!は保存済みの勤務依頼を返す" do
    work_request = WorkRequest.register!(
      attributes: {
        business: @earlier_request.business,
        required_skill: @earlier_request.required_skill,
        title: "登録した依頼",
        starts_at: Time.zone.local(2026, 8, 3, 10),
        ends_at: Time.zone.local(2026, 8, 3, 12),
        required_staff_count: 2,
        status: :open
      }
    )

    assert_predicate work_request, :persisted?
    assert_equal "登録した依頼", work_request.title
  end

  test "register!は保存失敗時にRecordInvalidを送出する" do
    assert_raises ActiveRecord::RecordInvalid do
      WorkRequest.register!(
        attributes: {
          title: ""
        }
      )
    end
  end

  test "update_details!は更新済みの勤務依頼を返す" do
    work_request = WorkRequest.update_details!(
      id: @earlier_request.id,
      attributes: {
        title: "更新した依頼",
        required_staff_count: 3
      }
    )

    assert_equal @earlier_request, work_request
    assert_equal "更新した依頼", work_request.title
    assert_equal 3, work_request.required_staff_count
  end

  test "cancel!は取消状態へ変更した勤務依頼を返す" do
    work_request = WorkRequest.cancel!(
      id: @earlier_request.id
    )

    assert_predicate work_request, :cancelled?
    assert_equal @earlier_request, work_request
  end

  test "remove!は割当のない下書きの勤務依頼を削除して返す" do
    @earlier_request.draft!

    work_request = WorkRequest.remove!(
      id: @earlier_request.id
    )

    assert_predicate work_request, :destroyed?

    assert_raises ActiveRecord::RecordNotFound do
      WorkRequest.find(@earlier_request.id)
    end
  end

  test "remove!は公開済みまたは割当のある勤務依頼を削除しない" do
    assert_raises ActiveRecord::RecordNotDestroyed do
      WorkRequest.remove!(id: @earlier_request.id)
    end

    @earlier_request.draft!

    staff_member = StaffMember.create!(
      name: "削除制限スタッフ",
      employment_status: :active
    )

    Assignment.assign!(
      work_request_id: @earlier_request.id,
      staff_member_id: staff_member.id
    )

    assert_raises ActiveRecord::RecordNotDestroyed do
      WorkRequest.remove!(id: @earlier_request.id)
    end

    assert_predicate @earlier_request.reload, :persisted?
  end

  test "存在しないIDはRecordNotFoundを送出する" do
    missing_id = WorkRequest.maximum(:id).to_i + 1

    assert_raises ActiveRecord::RecordNotFound do
      WorkRequest.update_details!(
        id: missing_id,
        attributes: {
          title: "更新"
        }
      )
    end

    assert_raises ActiveRecord::RecordNotFound do
      WorkRequest.cancel!(id: missing_id)
    end

    assert_raises ActiveRecord::RecordNotFound do
      WorkRequest.remove!(id: missing_id)
    end
  end
end

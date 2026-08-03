require "test_helper"

class AvailabilityTest < ActiveSupport::TestCase
  setup do
    @staff_member = StaffMember.create!(
      name: "勤務可否テスト",
      employment_status: :active
    )

    @starts_at = Time.zone.local(2026, 8, 10, 9)
  end

  test "register_or_update!は勤務可否を登録して保存済みモデルを返す" do
  availability = nil

  assert_difference("ChangeEvent.count", 1) do
    availability = Availability.register_or_update!(
      attributes: {
        staff_member: @staff_member,
        starts_at: @starts_at,
        ends_at: @starts_at + 8.hours,
        status: :available
      }
    )
  end

  assert_predicate availability, :persisted?
  assert_predicate availability, :available?
end

  test "register_or_update!は同じスタッフと開始日時の勤務可否を更新する" do
    original = Availability.register_or_update!(
      attributes: {
        staff_member: @staff_member,
        starts_at: @starts_at,
        ends_at: @starts_at + 8.hours,
        status: :available
      }
    )

    updated = Availability.register_or_update!(
      attributes: {
        staff_member: @staff_member,
        starts_at: @starts_at,
        ends_at: @starts_at + 4.hours,
        status: :unavailable,
        notes: "予定変更"
      }
    )

    assert_equal original.id, updated.id
    assert_predicate updated, :unavailable?
    assert_equal "予定変更", updated.notes
  end
  test "register_or_update!は実質的な変更がない場合に変更記録を作らない" do
  attributes = {
    staff_member: @staff_member,
    starts_at: @starts_at,
    ends_at: @starts_at + 8.hours,
    status: :available
  }

  Availability.register_or_update!(attributes: attributes)

  assert_no_difference("ChangeEvent.count") do
    Availability.register_or_update!(attributes: attributes)
  end
end

  test "for_staffは対象スタッフの勤務可否を開始日時順で返す" do
    later = Availability.register_or_update!(
      attributes: {
        staff_member: @staff_member,
        starts_at: @starts_at + 1.day,
        ends_at: @starts_at + 1.day + 8.hours,
        status: :available
      }
    )

    earlier = Availability.register_or_update!(
      attributes: {
        staff_member: @staff_member,
        starts_at: @starts_at,
        ends_at: @starts_at + 8.hours,
        status: :available
      }
    )

    result = Availability.for_staff(
      staff_member_id: @staff_member.id
    )

    assert_kind_of ActiveRecord::Relation, result
    assert_equal [ earlier, later ], result.to_a
  end

  test "register_or_update!は保存失敗時にRecordInvalidを送出する" do
    assert_raises ActiveRecord::RecordInvalid do
      Availability.register_or_update!(
        attributes: {
          staff_member: @staff_member,
          starts_at: @starts_at
        }
      )
    end
  end

  test "remove!は削除した勤務可否を返す" do
    availability = Availability.register_or_update!(
      attributes: {
        staff_member: @staff_member,
        starts_at: @starts_at,
        ends_at: @starts_at + 8.hours,
        status: :available
      }
    )

    removed = Availability.remove!(id: availability.id)

    assert_predicate removed, :destroyed?

    assert_raises ActiveRecord::RecordNotFound do
      Availability.find(availability.id)
    end
  end
end

require "test_helper"

class SeedDataTest < ActiveSupport::TestCase
  test "基準seedは変更記録の対象種別を業務データに合わせて冪等に保存する" do
    load Rails.root.join("db/seeds.rb")

    availability_event = ChangeEvent.source_seed.find_by!(
      summary: "休田 やすみさんの勤務可否を更新しました"
    )

    assignment_event = ChangeEvent.source_seed.find_by!(
      summary:
        "清水 さくらさんを勤務依頼「式典配膳」へ仮割当しました"
    )

    confirmed_event = ChangeEvent.source_seed.find_by!(
      summary:
        "清水 さくらさんの勤務依頼「共用部清掃」への割当を確定しました"
    )

    assert_predicate(
      availability_event,
      :target_type_availability?
    )

    assert_predicate(
      assignment_event,
      :target_type_assignment?
    )

    assert_predicate(
      confirmed_event,
      :target_type_assignment?
    )

    assert_predicate(
      Assignment.find(confirmed_event.target_id),
      :confirmed?
    )

    assert_no_difference("ChangeEvent.source_seed.count") do
      load Rails.root.join("db/seeds.rb")
    end
  end
end

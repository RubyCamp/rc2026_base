require "test_helper"

class BusinessTest < ActiveSupport::TestCase
  test "for_selectionは有効な取引先だけを名称順で返す" do
    later = Business.create!(
      name: "B社",
      contact_name: "担当者",
      contact_phone: "00-0000-0000"
    )

    earlier = Business.create!(
      name: "A社",
      contact_name: "担当者",
      contact_phone: "00-0000-0001"
    )

    inactive = Business.create!(
      name: "停止中",
      contact_name: "担当者",
      contact_phone: "00-0000-0002",
      active: false
    )

    result = Business.for_selection.where(
      id: [ later.id, earlier.id, inactive.id ]
    )

    assert_kind_of ActiveRecord::Relation, result
    assert_equal [ earlier, later ], result.to_a
  end
end

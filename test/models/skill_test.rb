require "test_helper"

class SkillTest < ActiveSupport::TestCase
  test "for_selectionは有効なスキルだけを名称順で返す" do
    later = Skill.create!(
      code: "B_#{SecureRandom.hex(4)}",
      name: "Bスキル"
    )

    earlier = Skill.create!(
      code: "A_#{SecureRandom.hex(4)}",
      name: "Aスキル"
    )

    inactive = Skill.create!(
      code: "X_#{SecureRandom.hex(4)}",
      name: "停止中",
      active: false
    )

    result = Skill.for_selection.where(
      id: [ later.id, earlier.id, inactive.id ]
    )

    assert_kind_of ActiveRecord::Relation, result
    assert_equal [ earlier, later ], result.to_a
  end
end
class SkillTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

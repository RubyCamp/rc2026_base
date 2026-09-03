require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "担当チームの対応表を一元管理する" do
    expected = {
      "guide#index" => "統合版",
      "sessions#new" => "Team 3",
      "admin/calendar#index" => "Team 3",
      "provider/work_requests#new" => "Team 3",
      "details_of_shifts#index" => "Team 4",
      "work_requests#show" => "Team 1 / Team 5",
      "work_requests#shift" => "Team 5",
      "availabilities#index" => "Team 6",
      "change_events#index" => "Team 2",
      "list_views#index" => "Team 1",
      "staff_members#index" => "共通基盤",
      "admin/demo_data#index" => "統合版"
    }

    expected.each do |page, owner|
      assert_equal owner, ApplicationHelper::PAGE_OWNERSHIP.fetch(page)
    end
  end

  test "未登録のHTMLアクションは共通基盤として扱う" do
    controller = ActionView::TestCase::TestController.new
    controller.define_singleton_method(:controller_path) { "unmapped" }
    controller.define_singleton_method(:action_name) { "index" }
    view = controller.view_context

    assert_equal "共通基盤", view.page_ownership_label
  end
end

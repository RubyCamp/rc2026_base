require "test_helper"

class PageOwnershipControllerTest < ActionDispatch::IntegrationTest
  setup do
    @business = Business.create!(
      name: "担当表示確認事業者",
      contact_name: "表示確認担当",
      contact_phone: "00-0000-0000"
    )
    @skill = Skill.create!(code: "ownership-test", name: "担当表示確認技能")
    @work_request = WorkRequest.create!(
      business: @business,
      required_skill: @skill,
      title: "担当表示確認依頼",
      starts_at: Time.zone.parse("2030-01-01 09:00"),
      ends_at: Time.zone.parse("2030-01-01 12:00"),
      required_staff_count: 1,
      status: :open
    )
    @staff_member = StaffMember.create!(name: "担当表示確認スタッフ")
    @availability = Availability.create!(
      staff_member: @staff_member,
      starts_at: Time.zone.parse("2030-01-01 09:00"),
      ends_at: Time.zone.parse("2030-01-01 12:00"),
      status: :available
    )
  end

  test "主要な画面に担当チームを表示する" do
    representative_pages = [
      [ root_path, "統合版" ],
      [ login_path, "Team 3" ],
      [ work_requests_path, "Team 1 / Team 5" ],
      [ work_requests_shift_path, "Team 5" ],
      [ availabilities_path, "Team 6" ],
      [ details_of_shifts_path, "Team 4" ],
      [ list_views_path, "Team 1" ],
      [ change_events_path, "Team 2" ],
      [ staff_members_path, "共通基盤" ],
      [ provider_detail_path, "Team 3" ],
      [ new_provider_work_request_path, "Team 3" ],
      [ admin_calendar_path, "Team 3" ],
      [ admin_demo_data_path, "統合版" ],
      [ examples_local_data_path, "共通基盤" ]
    ]

    representative_pages.each do |path, owner|
      assert_page_owner(path, owner)
    end
  end

  test "チュートリアル画面にも共通基盤ラベルを表示する" do
    assert_page_owner(tutorial_path, "共通基盤")
  end

  test "詳細・編集・新規画面にも担当チームを表示する" do
    post login_path, params: { role: "business", business_id: @business.id }

    pages = [
      [ work_request_path(@work_request), "Team 1 / Team 5" ],
      [ edit_work_request_path(@work_request), "Team 1 / Team 5" ],
      [ details_of_shift_path(@work_request), "Team 4" ],
      [ edit_details_of_shift_path(@work_request), "Team 4" ],
      [ new_availability_path, "Team 6" ],
      [ edit_availability_path(@availability), "Team 6" ],
      [ provider_work_request_path(@work_request), "Team 3" ],
      [ edit_provider_work_request_path(@work_request), "Team 3" ]
    ]

    pages.each do |path, owner|
      assert_page_owner(path, owner)
    end
  end

  private

  def assert_page_owner(path, owner)
    get path

    assert_response :success, "#{path} の応答が成功していません"
    assert_select "[data-page-ownership=?]", owner, count: 1
    assert_select "[aria-label='画面の担当チーム']", count: 1
  end
end

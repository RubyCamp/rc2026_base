require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @business = Business.create!(
      name: "ログイン確認会館",
      contact_name: "確認担当",
      contact_phone: "00-1111-2222"
    )
  end

  test "ルートは全体案内を直接表示する" do
    get root_path

    assert_response :success
    assert_select "h1", text: "勤務調整の流れ"
  end

  test "ログイン画面は引き続き表示できる" do
    get login_path

    assert_response :success
    assert_select "h1", text: "ログイン"
  end

  test "管理者ログインは管理カレンダーへ遷移する" do
    post login_path, params: { role: "admin" }

    assert_redirected_to admin_calendar_path
  end

  test "事業者ログインは事業者画面へ遷移する" do
    post login_path, params: { role: "business", business_id: @business.id }

    assert_redirected_to provider_detail_path
  end
end

require "test_helper"

class AdminDemoDataControllerTest < ActionDispatch::IntegrationTest
  setup do
    DemoData::Manager.cleanup!
  end

  test "PIN未入力では管理画面の操作を実行できない" do
    assert_no_difference("DemoDataBatch.count") do
      post admin_demo_data_batches_path, params: { seed: 1 }
    end

    assert_redirected_to admin_demo_data_path
    follow_redirect!
    assert_select "input[name='demo_data[pin]']"
  end

  test "専用PINで解除し、追加と再ロックを行える" do
    post admin_authenticate_demo_data_path, params: { demo_data: { pin: "0000" } }
    assert_redirected_to admin_demo_data_path
    assert_not session[:demo_data_admin_granted]

    post admin_authenticate_demo_data_path, params: { demo_data: { pin: "1234" } }
    assert_redirected_to admin_demo_data_path
    assert session[:demo_data_admin_granted]

    assert_difference("DemoDataBatch.count", 1) do
      post admin_demo_data_batches_path, params: { seed: 4001 }
    end

    get admin_demo_data_path
    assert_response :success
    assert_select "h1", text: "デモデータ管理"
    assert_select "td", text: /[0-9]+/

    delete admin_relock_demo_data_path
    assert_redirected_to admin_demo_data_path
    assert_not session[:demo_data_admin_granted]
  end

  test "resetと削除は明示確認がないと実行しない" do
    post admin_authenticate_demo_data_path, params: { demo_data: { pin: "1234" } }
    post admin_demo_data_batches_path, params: { seed: 4002 }

    assert_no_difference("DemoDataBatch.count") do
      patch admin_reset_demo_data_path, params: { seed: 4003 }
    end
    assert_no_difference("DemoDataBatch.count") do
      delete admin_demo_data_path
    end
  end

  test "確認後の削除は生成データだけを削除する" do
    manual_business = Business.create!(
      name: "削除対象外事業者",
      contact_name: "担当者",
      contact_phone: "00-0000-0000"
    )

    post admin_authenticate_demo_data_path, params: { demo_data: { pin: "1234" } }
    post admin_demo_data_batches_path, params: { seed: 4004 }

    assert_difference("DemoDataBatch.count", -1) do
      delete admin_demo_data_path, params: { confirm: "1" }
    end

    assert_predicate manual_business.reload, :persisted?
  end
end

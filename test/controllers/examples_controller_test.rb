require "test_helper"

class ExamplesControllerTest <
      ActionDispatch::IntegrationTest
  test "静的JSONとlocalStorageの独立した見本を表示する" do
    get examples_local_data_path

    assert_response :success

    assert_select(
      "h1",
      text: "静的JSONとブラウザ保存"
    )

    assert_select(
      "li",
      text: /中央駅北口/
    )

    assert_select(
      "[data-controller=local-storage]"
    )

    assert_select(
      ".text-body-secondary",
      text: /正式保存が必要な業務データには\s*PostgreSQL/
    )
  end
end

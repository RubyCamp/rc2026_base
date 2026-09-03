require "test_helper"

class ListViewsControllerTest < ActionDispatch::IntegrationTest
  setup do
    DemoData::Manager.cleanup!
    DemoData::Manager.generate!(seed: 9100)
  end

  test "仮割当一覧は判定結果と表示順を保ったまま少ないクエリで表示する" do
    query_count = count_sql_queries do
      get list_views_path
    end

    assert_response :success
    assert_operator query_count, :<=, 12
    assert_select "h1", text: "仮割り当て一覧"

    displayed_titles = css_select("article.card .definition-list a").map(&:text)
    expected_titles = Assignment.draft_for_confirmation.to_a.map { |assignment| assignment.work_request.title }
    assert_equal expected_titles, displayed_titles

    assert_includes response.body, "時間重複"
    assert_includes response.body, "スキル不足"
    assert_includes response.body, "人数不足"
    assert_includes response.body, "OK"
  end

  test "スタッフ一覧のシフトモーダルも関連を再取得しない" do
    query_count = count_sql_queries do
      get staff_members_path
    end

    assert_response :success
    assert_operator query_count, :<=, 12
    assert_select "h1", text: "スタッフ一覧"
    assert_select "#shiftModal-#{StaffMember.first.id}"
  end

  test "確認一覧のpreloadはスタッフの依頼を再帰的に読み込まない" do
    assignments = Assignment.draft_for_confirmation.to_a
    staff_assignments = assignments.flat_map { |assignment| assignment.staff_member.assignments }

    assert_not_empty assignments
    assert assignments.all? { |assignment| assignment.staff_member.association(:assignments).loaded? }
    assert staff_assignments.all? { |assignment| assignment.association(:work_request).loaded? }
    assert staff_assignments.none? { |assignment| assignment.work_request.association(:assignments).loaded? }
  end

  test "一括判定は既存の個別判定結果と一致する" do
    assignments = Assignment.draft_for_confirmation.to_a
    judgments = Assignment.judgments_for(assignments)

    assignments.each do |assignment|
      work_request = assignment.work_request
      assert_equal(
        {
          skill_missing: !StaffMember.skilled_for(work_request_id: work_request.id).exists?(id: assignment.staff_member_id),
          staffing_shortage: !work_request.staffing_sufficient?,
          time_conflict: Assignment.time_conflict?(id: assignment.id)
        },
        judgments.fetch(assignment.id)
      )
    end
  end

  private

  def count_sql_queries
    count = 0
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
      payload = args.last
      sql = payload[:sql].to_s
      next if payload[:name] == "SCHEMA" || payload[:cached]
      next if sql.match?(/\A(?:BEGIN|COMMIT|ROLLBACK)/)

      count += 1
    end

    yield
    count
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end
end

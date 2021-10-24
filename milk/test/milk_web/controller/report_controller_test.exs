defmodule MilkWeb.ReportControllerTest do
  use MilkWeb.ConnCase
  use Common.Fixtures

  alias Milk.Relations

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create user report" do
    test "works", %{conn: conn} do
      reporter = fixture_user(num: 1)
      reportee = fixture_user(num: 2)

      conn =
        post(conn, Routes.report_path(conn, :create_user_report),
          report: %{reporter: reporter.id, reportee: reportee.id, report_types: [0]}
        )

      assert json_response(conn, 200)["result"]
    end
  end

  describe "create tournament report" do
    test "works (integer)", %{conn: conn} do
      user = fixture_user()
      tournament = fixture_tournament()

      conn =
        post(conn, Routes.report_path(conn, :create_tournament_report),
          report: %{reporter_id: user.id, tournament_id: tournament.id, report_type: 0}
        )

      assert json_response(conn, 200)["result"]
    end

    test "works (list)", %{conn: conn} do
      user = fixture_user()
      tournament = fixture_tournament()

      conn =
        post(conn, Routes.report_path(conn, :create_tournament_report),
          report: %{reporter_id: user.id, tournament_id: tournament.id, report_type: [0]}
        )

      assert json_response(conn, 200)["result"]

      conn =
        post(conn, Routes.report_path(conn, :create_tournament_report),
          report: %{reporter_id: user.id, tournament_id: tournament.id, report_types: [0]}
        )

      assert json_response(conn, 200)["result"]
    end

    test "block", %{conn: conn} do
      user = fixture_user()
      tournament = fixture_tournament()

      conn =
        post(conn, Routes.report_path(conn, :create_tournament_report),
          report: %{reporter_id: user.id, tournament_id: tournament.id, report_type: [6]}
        )

      assert json_response(conn, 200)["result"]

      Relations.blocked_users(user.id)
      |> Enum.map(fn block_relation ->
        assert block_relation.block_user_id == user.id
        assert block_relation.blocked_user_id == tournament.master_id
      end)
      |> length()
      |> (fn len ->
            assert len == 1
          end).()
    end
  end
end

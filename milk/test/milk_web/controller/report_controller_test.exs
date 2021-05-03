defmodule MilkWeb.ReportControllerTest do
  use MilkWeb.ConnCase

  alias Milk.{
    Accounts,
    Relations,
    Tournaments
  }

  @valid_tournament_attrs %{
    "capacity" => 42,
    "deadline" => "2010-04-17T14:00:00Z",
    "description" => "some description",
    "event_date" => "2010-04-17T14:00:00Z",
    "name" => "some_name",
    "type" => 0,
    "url" => "somesomeurl",
    "thumbnail_path" => "some path",
    "password" => "passwd",
    "master_id" => 1,
    "platform_id" => 1,
    "is_started" => true,
    "game_name" => "some game",
    "start_recruiting" => "2010-04-17T14:00:00Z"
  }

  defp fixture_user(n \\ 0) do
    attrs = %{"icon_path" => "some icon_path", "language" => "some language", "name" => to_string(n)<>"some name", "notification_number" => 42, "point" => 42, "email" => to_string(n)<>"some@email.com", "logout_fl" => true, "password" => "S1ome password"}
    {:ok, user} = Accounts.create_user(attrs)
    user
  end

  defp fixture_tournament(opts \\ []) do
    # FIXME: ここのデフォルト値は本当はfalseのほうがよさそう
    is_started =
      opts[:is_started]
      |> is_nil()
      |> unless do
        opts[:is_started]
      else
        true
      end

    master_id =
      opts[:master_id]
      |> is_nil()
      |> unless do
        opts[:master_id]
      else
        {:ok, user} = Accounts.create_user(%{"name" => "name", "email" => "e@mail.com", "password" => "Password123"})
        user.id
      end

    {:ok, tournament} =
      @valid_tournament_attrs
      |> Map.put("is_started", is_started)
      |> Map.put("master_id", master_id)
      |> Tournaments.create_tournament()
    tournament
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create user report" do
    test "works", %{conn: conn} do
      reporter = fixture_user(1)
      reportee = fixture_user(2)

      conn = post(conn, Routes.report_path(conn, :create_user_report), report: %{reporter: reporter.id, reportee: reportee.id, report_types: [0]})
      assert json_response(conn, 200)["result"]
    end
  end

  describe "create tournament report" do
    test "works (integer)", %{conn: conn} do
      user = fixture_user()
      tournament = fixture_tournament()

      conn = post(conn, Routes.report_path(conn, :create_tournament_report), report: %{reporter_id: user.id, tournament_id: tournament.id, report_type: 0})
      assert json_response(conn, 200)["result"]
    end

    test "works (list)", %{conn: conn} do
      user = fixture_user()
      tournament = fixture_tournament()

      conn = post(conn, Routes.report_path(conn, :create_tournament_report), report: %{reporter_id: user.id, tournament_id: tournament.id, report_type: [0]})
      assert json_response(conn, 200)["result"]
    end

    test "block", %{conn: conn} do
      user = fixture_user()
      tournament = fixture_tournament()

      conn = post(conn, Routes.report_path(conn, :create_tournament_report), report: %{reporter_id: user.id, tournament_id: tournament.id, report_type: [6]})
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

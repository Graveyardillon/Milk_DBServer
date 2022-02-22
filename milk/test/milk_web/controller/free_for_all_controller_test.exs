defmodule MilkWeb.FreeForAllControllerTest do
  @moduledoc """
  テスト
  """
  use MilkWeb.ConnCase
  use Common.Fixtures

  describe "get tables" do
    test "works", %{conn: conn} do
      tournament = fixture_tournament(
        rule: "freeforall",
        num: 20,
        round_number: 3,
        match_number: 1,
        round_capacity: 4,
        is_team: true,
        capacity: 16
      )

      fill_with_team(tournament.id)

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})
      assert json_response(conn, 200)["result"]

      conn = get(conn, Routes.free_for_all_path(conn, :get_tables), tournament_id: tournament.id)
      assert json_response(conn, 200)["result"]

      conn
      |> json_response(200)
      |> Map.get("data")
      |> Enum.map(fn table ->
        assert table["id"]
        assert table["name"]
        assert table["round_index"]
        assert table["tournament_id"] == tournament.id

        conn = get(conn, Routes.free_for_all_path(conn, :get_round_team_information), table_id: table["id"])
        assert json_response(conn, 200)["result"]

        conn
        |> json_response(200)
        |> Map.get("data")
        |> Enum.map(fn round ->
          assert round["table_id"] == table["id"]
          assert round["team_id"]
          assert round["id"]

          conn = get(conn, Routes.free_for_all_path(conn, :get_team_match_information), round_information_id: round["id"])
          assert json_response(conn, 200)["result"]
        end)
        |> Enum.empty?()
        |> refute()
      end)
      |> length()
      |> then(fn len ->
        assert len == 4
      end)
    end
  end
end

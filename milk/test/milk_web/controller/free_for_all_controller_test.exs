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
        assert table["name"]
        assert table["round_index"]
        assert table["tournament_id"] == tournament.id
      end)
      |> length()
      |> then(fn len ->
        assert len == 4
      end)
    end
  end
end

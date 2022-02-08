defmodule MilkWeb.EntryControllerTest do
  use MilkWeb.ConnCase
  use Common.Fixtures

  describe "create template" do
    test "just works", %{conn: conn} do
      tournament = fixture_tournament()

      conn = post(conn, Routes.entry_path(conn, :create_template), %{
        "entry_templates" => [
          %{"tournament_id" => tournament.id, "title" => "チーム名"},
          %{"tournament_id" => tournament.id, "title" => "RiotID1"},
          %{"tournament_id" => tournament.id, "title" => "RiotID2"},
          %{"tournament_id" => tournament.id, "title" => "RiotID3"},
          %{"tournament_id" => tournament.id, "title" => "RiotID4"},
          %{"tournament_id" => tournament.id, "title" => "RiotID5"}
        ]
      })

      assert json_response(conn, 200)["result"]
    end
  end
end

defmodule MilkWeb.EntryControllerTest do
  @moduledoc """
  entry
  """
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

      conn = get(conn, Routes.entry_path(conn, :get_template), %{tournament_id: tournament.id})

      conn
      |> json_response(200)
      |> Map.get("templates")
      |> Enum.each(fn template ->
        assert is_binary(template["title"])
      end)
    end
  end
end

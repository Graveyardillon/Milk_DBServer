defmodule MilkWeb.EntryControllerTest do
  @moduledoc """
  entry
  """
  use MilkWeb.ConnCase
  use Common.Fixtures

  import Common.Sperm

  alias Milk.Tournaments

  describe "create template" do
    test "just works", %{conn: conn} do
      tournament = fixture_tournament(is_team: true, capacity: 4)

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

      teams = fill_with_team(tournament.id)

      teams
      |> hd()
      |> Map.get(:id)
      |> Tournaments.get_leader()
      |> Map.get(:user_id)
      ~> leader_id

      conn = post(conn, Routes.entry_path(conn, :create_entry_information), %{
        "tournament_id" => tournament.id,
        "user_id" => leader_id,
        "entry_information" => [
          %{"title" => "チーム名", "field" => "my team"},
          %{"title" => "RiotID1", "field" => "asdf#1234"},
          %{"title" => "RiotID2", "field" => "asdf#1234"},
          %{"title" => "RiotID3", "field" => "asdf#1234"},
          %{"title" => "RiotID4", "field" => "asdf#1234"},
          %{"title" => "RiotID5", "field" => "asdf#1234"},
        ]
      })

      assert json_response(conn, 200)["result"]
    end
  end
end

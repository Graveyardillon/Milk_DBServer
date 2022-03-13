defmodule MilkWeb.FreeForAllControllerTest do
  @moduledoc """
  テスト
  """
  import Common.Sperm

  use MilkWeb.ConnCase
  use Common.Fixtures

  alias Milk.Tournaments
  alias Milk.Tournaments.Rules.FreeForAll

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

  describe "state machine" do
    test "freeforall (individual)", %{conn: conn} do
      user = fixture_user()
      attrs = %{
        "capacity" => 8,
        "deadline" => "2010-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2010-04-17T14:00:00Z",
        "master_id" => user.id,
        "name" => "some name",
        "type" => 1,
        "join" => "false",
        "url" => "some url",
        "platform" => 1,
        "rule" => "freeforall",
        "round_number" => 2,
        "match_number" => 1,
        "round_capacity" => 3,
        "is_team" => "false",
      }

      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: "")

      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["data"]["rule"] == "freeforall"
      refute json_response(conn, 200)["data"]["is_team"]

      master_id = json_response(conn, 200)["data"]["master_id"]
      tournament_id = json_response(conn, 200)["data"]["id"]
      _capacity = json_response(conn, 200)["data"]["capacity"]
      _team_size = json_response(conn, 200)["data"]["team_size"]

      _entrants = fill_with_entrant(tournament_id)

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => master_id})
      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["state"] == "IsNotStarted"

      conn = post(conn, Routes.tournament_path(conn, :start), %{"tournament" => %{"master_id" => master_id, "tournament_id" => tournament_id}})
      assert json_response(conn, 200)["result"]

      conn = get(conn, Routes.free_for_all_path(conn, :get_tables), tournament_id: tournament_id)

      conn
      |> json_response(200)
      |> Map.get("data")
      |> Enum.map(fn table ->
        conn = get(conn, Routes.free_for_all_path(conn, :get_round_information), table_id: table["id"])
        conn
        |> json_response(200)
        |> Map.get("data")
        |> Enum.with_index(fn element, index ->
          {element, index}
        end)
        |> Enum.map(fn {entrant, index} ->
          %{"score" => index, "user_id" => entrant["user_id"]}
        end)
        ~> scores

        conn = post(conn, Routes.free_for_all_path(conn, :claim_scores), %{"tournament_id" => tournament_id, "scores" => scores, "table_id" => table["id"]})
        assert json_response(conn, 200)["result"]
      end)

      conn = get(conn, Routes.free_for_all_path(conn, :get_tables), tournament_id: tournament_id)

      conn
      |> json_response(200)
      |> Map.get("data")
      |> Enum.map(fn table ->
        conn = get(conn, Routes.free_for_all_path(conn, :get_round_information), table_id: table["id"])
        conn
        |> json_response(200)
        |> Map.get("data")
        |> Enum.with_index(fn element, index ->
          {element, index}
        end)
        |> Enum.map(fn {entrant, index} ->
          %{"score" => index, "user_id" => entrant["user_id"]}
        end)
        ~> scores

        conn = post(conn, Routes.free_for_all_path(conn, :claim_scores), %{"tournament_id" => tournament_id, "scores" => scores, "table_id" => table["id"]})
        assert json_response(conn, 200)["result"]
      end)

      refute Tournaments.get_tournament(tournament_id)
    end

    test "freeforall (individual) (enable point multiplier)", %{conn: conn} do
      user = fixture_user()
      attrs = %{
        "capacity" => 8,
        "deadline" => "2010-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2010-04-17T14:00:00Z",
        "master_id" => user.id,
        "name" => "some name",
        "type" => 1,
        "join" => "false",
        "url" => "some url",
        "platform" => 1,
        "rule" => "freeforall",
        "round_number" => 2,
        "match_number" => 1,
        "round_capacity" => 3,
        "is_team" => "false",
        "enable_point_multiplier" => true,
        "point_multiplier_categories" => [
          %{"name" => "キルポ", "multiplier" => 10},
          %{"name" => "ダメージ", "multiplier" => 0.5}
        ]
      }

      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: "")
      assert json_response(conn, 200)["result"]
    end

    test "freeforall (team)", %{conn: conn} do
      user = fixture_user()
      attrs = %{
        "capacity" => 8,
        "deadline" => "2010-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2010-04-17T14:00:00Z",
        "master_id" => user.id,
        "name" => "some name",
        "url" => "some url",
        "platform" => 1,
        "rule" => "freeforall",
        "round_number" => 2,
        "match_number" => 1,
        "round_capacity" => 3,
        "is_team" => "true",
        "team_size" => 4
      }

      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: "")

      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["data"]["rule"] === "freeforall"
      assert json_response(conn, 200)["data"]["is_team"]

      master_id = json_response(conn, 200)["data"]["master_id"]
      tournament_id = json_response(conn, 200)["data"]["id"]

      fill_with_team(tournament_id)

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => master_id})
      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["state"] == "IsNotStarted"

      conn = post(conn, Routes.tournament_path(conn, :start), %{"tournament" => %{"master_id" => master_id, "tournament_id" => tournament_id}})
      assert json_response(conn, 200)["result"]

      conn = get(conn, Routes.free_for_all_path(conn, :get_tables), tournament_id: tournament_id)

      conn
      |> json_response(200)
      |> Map.get("data")
      |> Enum.map(fn table ->
        conn = get(conn, Routes.free_for_all_path(conn, :get_round_team_information), table_id: table["id"])
        conn
        |> json_response(200)
        |> Map.get("data")
        |> Enum.with_index(fn element, index ->
          {element, index}
        end)
        |> Enum.map(fn {team, index} ->
          %{"score" => index, "team_id" => team["team_id"], "member_scores" => []}
        end)
        ~> scores

        conn = post(conn, Routes.free_for_all_path(conn, :claim_scores), %{"tournament_id" => tournament_id, "scores" => scores, "table_id" => table["id"]})
        assert json_response(conn, 200)["result"]
      end)
      |> Enum.empty?()
      |> refute()

      conn = get(conn, Routes.free_for_all_path(conn, :get_tables), tournament_id: tournament_id)

      conn
      |> json_response(200)
      |> Map.get("data")
      |> Enum.map(fn table ->
        conn = get(conn, Routes.free_for_all_path(conn, :get_round_team_information), table_id: table["id"])
        conn
        |> json_response(200)
        |> Map.get("data")
        |> Enum.with_index(fn element, index ->
          {element, index}
        end)
        |> Enum.map(fn {team, index} ->
          %{"score" => index, "team_id" => team["team_id"], "member_scores" => []}
        end)
        ~> scores

        conn = post(conn, Routes.free_for_all_path(conn, :claim_scores), %{"tournament_id" => tournament_id, "scores" => scores, "table_id" => table["id"]})
        assert json_response(conn, 200)["result"]
      end)
      |> Enum.empty?()
      |> refute()

      refute Tournaments.get_tournament(tournament_id)

      conn = get(conn, Routes.free_for_all_path(conn, :get_tables), tournament_id: tournament_id)

      conn
      |> json_response(200)
      |> Map.get("data")
      |> Enum.map(fn table ->
        conn = get(conn, Routes.free_for_all_path(conn, :get_round_team_information), table_id: table["id"])

        conn
        |> json_response(200)
        |> Map.get("data")
        |> Enum.map(fn round_info ->
          conn = get(conn, Routes.free_for_all_path(conn, :load_team_match_information), round_information_id: round_info["id"])

          conn
          |> json_response(200)
          |> Map.get("data")
          |> Enum.empty?()
          |> refute()
        end)
        |> Enum.empty?()
        |> refute()
      end)
      |> Enum.empty?()
      |> refute()
    end

    test "freeforall (team) (enable point multiplier)", %{conn: conn} do
      user = fixture_user()
      attrs = %{
        "capacity" => 8,
        "deadline" => "2010-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2010-04-17T14:00:00Z",
        "master_id" => user.id,
        "name" => "some name",
        "type" => 1,
        "url" => "some url",
        "platform" => 1,
        "rule" => "freeforall",
        "round_number" => 2,
        "match_number" => 1,
        "round_capacity" => 3,
        "is_team" => "true",
        "enable_point_multiplier" => true,
        "point_multiplier_categories" => [
          %{"name" => "キルポ", "multiplier" => 10},
          %{"name" => "ダメージ", "multiplier" => 0.5}
        ],
        "team_size" => 4
      }

      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: "")
      assert json_response(conn, 200)["result"]

      assert json_response(conn, 200)["data"]["rule"] === "freeforall"
      assert json_response(conn, 200)["data"]["is_team"]

      master_id = json_response(conn, 200)["data"]["master_id"]
      tournament_id = json_response(conn, 200)["data"]["id"]

      fill_with_team(tournament_id)

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => master_id})
      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["state"] == "IsNotStarted"

      conn = post(conn, Routes.tournament_path(conn, :start), %{"tournament" => %{"master_id" => master_id, "tournament_id" => tournament_id}})
      assert json_response(conn, 200)["result"]

      conn = get(conn, Routes.free_for_all_path(conn, :get_categories), tournament_id: tournament_id)
      categories = json_response(conn, 200)["data"]

      conn = get(conn, Routes.free_for_all_path(conn, :get_tables), tournament_id: tournament_id)

      conn
      |> json_response(200)
      |> Map.get("data")
      |> Enum.map(fn table ->
        conn = get(conn, Routes.free_for_all_path(conn, :get_round_team_information), table_id: table["id"])
        conn
        |> json_response(200)
        |> Map.get("data")
        |> Enum.with_index(fn element, index ->
          {element, index}
        end)
        |> Enum.map(fn {team, index} ->
          %{
            "scores" => Enum.map(categories, fn category ->
              %{
                "score" => index,
                "category_id" => category["id"]
              }
            end),
            "team_id" => team["team_id"],
            "member_scores" => []
          }
        end)
        ~> scores

        conn = post(conn, Routes.free_for_all_path(conn, :claim_scores), %{"tournament_id" => tournament_id, "scores_with_categories" => scores, "table_id" => table["id"]})
        assert json_response(conn, 200)["result"]
      end)
      |> Enum.empty?()
      |> refute()

      conn = get(conn, Routes.free_for_all_path(conn, :get_tables), tournament_id: tournament_id)

      conn
      |> json_response(200)
      |> Map.get("data")
      |> Enum.map(fn table ->
        conn = get(conn, Routes.free_for_all_path(conn, :get_round_team_information), table_id: table["id"])
        conn
        |> json_response(200)
        |> Map.get("data")
        |> Enum.with_index(fn element, index ->
          {element, index}
        end)
        |> Enum.map(fn {team, index} ->
          %{
            "scores" => Enum.map(categories, fn category ->
              %{
                "score" => index,
                "category_id" => category["id"]
              }
            end),
            "team_id" => team["team_id"],
            "member_scores" => []
          }
        end)
        ~> scores

        conn = post(conn, Routes.free_for_all_path(conn, :claim_scores), %{"tournament_id" => tournament_id, "scores_with_categories" => scores, "table_id" => table["id"]})
        assert json_response(conn, 200)["result"]
      end)
      |> Enum.empty?()
      |> refute()

      refute Tournaments.get_tournament(tournament_id)
    end
  end
end

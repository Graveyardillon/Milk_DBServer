defmodule MilkWeb.FreeForAllController do
  @moduledoc """
  複雑な処理になりそうだったので、tournament_controllerでなくこっちに記述
  """
  use MilkWeb, :controller
  import Common.Sperm

  alias Common.Tools

  alias Milk.Tournaments.Rules.FreeForAll
  alias Milk.Tournaments

  def get_tables(conn, %{"tournament_id" => tournament_id}) do
    tournament_id
    |> Tools.to_integer_as_needed()
    |> FreeForAll.get_tables_by_tournament_id()
    ~> tables

    render(conn, "tables.json", tables: tables)
  end

  def get_round_information(conn, %{"table_id" => table_id}) do
    table_id
    |> Tools.to_integer_as_needed()
    |> FreeForAll.get_round_information()
    ~> information_list

    render(conn, "round_information.json", %{information: information_list})
  end

  def get_round_team_information(conn, %{"table_id" => table_id}) do
    table_id
    |> Tools.to_integer_as_needed()
    |> FreeForAll.get_round_team_information()
    ~> information_list

    render(conn, "round_team_information.json", team_information: information_list)
  end

  def get_match_information(conn, %{"round_information_id" => round_information_id}) do
    round_information_id
    |> Tools.to_integer_as_needed()
    |> FreeForAll.get_match_information()
    ~> match_information_list

    render(conn, "match_information.json", match_information: match_information_list)
  end

  def get_team_match_information(conn, %{"round_information_id" => round_information_id}) do
    round_information_id
    |> Tools.to_integer_as_needed()
    |> FreeForAll.get_team_match_information()
    ~> match_information_list

    render(conn, "team_match_information.json", team_match_information: match_information_list)
  end

  def get_current_status(conn, %{"tournament_id" => tournament_id}) do
    tournament_id
    |> Tools.to_integer_as_needed()
    |> FreeForAll.get_status_by_tournament_id()
    ~> status

    render(conn, "status.json", status: status)
  end

  def claim_scores(conn, %{"tournament_id" => tournament_id, "table_id" => table_id, "scores" => scores}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    tournament = Tournaments.get_tournament(tournament_id)

    with {:ok, _} <- FreeForAll.claim_scores(tournament, table_id, scores),
         {:ok, _} <- FreeForAll.increase_current_match_index(table_id),
         {:ok, _} <- FreeForAll.finish_table_as_needed(table_id) do
      json(conn, %{result: true})
    else
      {:error, error} -> json(conn, %{result: false, error: error})
      _               -> json(conn, %{result: true})
    end
  end
end

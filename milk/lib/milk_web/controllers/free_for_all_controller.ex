defmodule MilkWeb.FreeForAllController do
  @moduledoc """
  複雑な処理になりそうだったので、tournament_controllerでなくこっちに記述
  """
  use MilkWeb, :controller
  import Common.Sperm

  alias Common.Tools

  alias Milk.Tournaments.Rules.FreeForAll

  def get_tables(conn, %{"tournament_id" => tournament_id}) do
    tournament_id
    |> Tools.to_integer_as_needed()
    |> FreeForAll.get_tables_by_tournament_id()
    ~> tables

    render(conn, "tables.json", tables: tables)
  end

  def get_round_team_information(conn, %{"table_id" => table_id}) do
    table_id
    |> Tools.to_integer_as_needed()
    |> FreeForAll.get_round_team_information()
    ~> information_list

    render(conn, "round_team_information.json", team_information: information_list)
  end

  def get_team_match_information(conn, %{"round_information_id" => round_information_id}) do
    round_information_id
    |> Tools.to_integer_as_needed()
    |> FreeForAll.get_team_match_information()
    ~> match_information_list

    render(conn, "team_match_information.json", team_match_information: match_information_list)
  end
end

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

    render(conn, "index.json", tables: tables)
  end
end

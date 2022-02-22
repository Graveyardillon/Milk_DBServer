defmodule MilkWeb.FreeForAllView do
  @moduledoc """
  free for all
  """
  use MilkWeb, :view

  def render("index.json", %{tables: tables}) do
    %{
      data: Enum.map(tables, fn table ->
        %{
          name: table.name,
          round_index: table.round_index,
          tournament_id: table.tournament_id
        }
      end),
      result: true
    }
  end

  def render("show.json", %{table: table}) do
    %{
      data: render_one(table, __MODULE__, "table.json"),
      result: true
    }
  end

  def render("table.json", %{table: table}) do
    %{
      name: table.name,
      round_index: table.round_index,
      tournament_id: table.tournament_id
    }
  end
end

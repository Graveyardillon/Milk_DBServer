defmodule MilkWeb.FreeForAllView do
  @moduledoc """
  free for all
  """
  use MilkWeb, :view

  def render("tables.json", %{tables: tables}) do
    %{
      data: Enum.map(tables, fn table ->
        %{
          id: table.id,
          name: table.name,
          round_index: table.round_index,
          tournament_id: table.tournament_id,
          is_finished: table.is_finished,
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
      id: table.id,
      name: table.name,
      round_index: table.round_index,
      tournament_id: table.tournament_id
    }
  end

  def render("round_team_information.json", %{team_information: team_information}) do
    %{
      data: Enum.map(team_information, fn team_info ->
        %{
          id: team_info.id,
          table_id: team_info.table_id,
          team_id: team_info.team_id
        }
      end),
      result: true
    }
  end

  def render("round_information.json", %{information: information}) do
    %{
      data: Enum.map(information, fn info ->
        %{
          id: info.id,
          table_id: info.table_id,
          user_id: info.user_id
        }
      end),
      result: true
    }
  end

  def render("team_match_information.json", %{team_match_information: team_match_information}) do
    %{
      data: Enum.map(team_match_information, fn team_info ->
        %{
          score: team_info.score,
          round_id: team_info.round_id
        }
      end),
      result: true
    }
  end

  def render("status.json", %{status: status}) do
    %{
      data: %{
        current_match_index: status.current_match_index,
        tournament_id: status.tournament_id
      }
    }
  end
end

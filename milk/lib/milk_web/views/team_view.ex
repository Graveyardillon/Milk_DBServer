defmodule MilkWeb.TeamView do
  use MilkWeb, :view

  alias MilkWeb.TeamView

  def render("index.json", %{teams: teams}) do
    %{
      data: render_many(teams, TeamView, "team.json")
    }
  end

  def render("show.json", %{team: team}) do
    %{
      data: render_one(team, TeamView, "team.json")
    }
  end

  def render("team.json", %{team: team}) do
    %{
      name: team.name,
      size: team.size,
      tournament_id: team.tournament_id
    }
  end
end

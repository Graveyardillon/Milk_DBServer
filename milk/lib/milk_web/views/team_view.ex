defmodule MilkWeb.TeamView do
  use MilkWeb, :view

  alias MilkWeb.TeamView

  def render("index.json", %{teams: teams}) do
    %{
      data: render_many(teams, TeamView, "team.json"),
      result: true
    }
  end

  def render("show.json", %{team: team}) do
    %{
      data: render_one(team, TeamView, "team.json"),
      result: true
    }
  end

  def render("team.json", %{team: team}) do
    %{
      id: team.id,
      name: team.name,
      size: team.size,
      tournament_id: team.tournament_id
    }
  end

  def render("error.json", %{error: error}) do
    if error do
      %{result: false, error: error, data: nil}
    else
      %{result: false, error: nil, data: nil}
    end
  end
end

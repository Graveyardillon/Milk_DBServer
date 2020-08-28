defmodule MilkWeb.TournamentView do
  use MilkWeb, :view
  alias MilkWeb.TournamentView

  def render("index.json", %{tournament: tournament}) do
    %{data: render_many(tournament, TournamentView, "tournament.json")}
  end

  def render("show.json", %{tournament: tournament}) do
    %{data: render_one(tournament, TournamentView, "tournament.json")}
  end

  def render("tournament.json", %{tournament: tournament}) do
    %{id: tournament.id,
      name: tournament.name,
      game_id: tournament.game_id,
      event_date: tournament.event_date,
      capacity: tournament.capacity,
      description: tournament.description,
      master_id: tournament.master_id,
      deadline: tournament.deadline,
      type: tournament.type,
      url: tournament.url}
  end
end

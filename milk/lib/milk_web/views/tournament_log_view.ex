defmodule MilkWeb.TournamentLogView do
  use MilkWeb, :view
  alias MilkWeb.TournamentLogView

  def render("index.json", %{tournament_log: tournament_log}) do
    %{data: render_many(tournament_log, TournamentLogView, "tournament_log.json")}
  end

  def render("show.json", %{tournament_log: tournament_log}) do
    %{data: render_one(tournament_log, TournamentLogView, "tournament_log.json")}
  end

  def render("tournament_log.json", %{tournament_log: tournament_log}) do
    %{id: tournament_log.id,
      name: tournament_log.name,
      game_id: tournament_log.game_id,
      event_date: tournament_log.event_date,
      capacity: tournament_log.capacity,
      description: tournament_log.description,
      master_id: tournament_log.master_id,
      deadline: tournament_log.deadline,
      type: tournament_log.type,
      url: tournament_log.url}
  end
end

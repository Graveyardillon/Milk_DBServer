defmodule MilkWeb.EntrantLogView do
  use MilkWeb, :view
  alias MilkWeb.EntrantLogView

  def render("index.json", %{entrant_log: entrant_log}) do
    %{data: render_many(entrant_log, EntrantLogView, "entrant_log.json")}
  end

  def render("show.json", %{entrant_log: entrant_log}) do
    %{data: render_one(entrant_log, EntrantLogView, "entrant_log.json")}
  end

  def render("entrant_log.json", %{entrant_log: entrant_log}) do
    %{
      id: entrant_log.id,
      tournament_id: entrant_log.tournament_id,
      user_id: entrant_log.user_id,
      rank: entrant_log.rank
    }
  end
end

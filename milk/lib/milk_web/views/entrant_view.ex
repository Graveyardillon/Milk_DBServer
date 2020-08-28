defmodule MilkWeb.EntrantView do
  use MilkWeb, :view
  alias MilkWeb.EntrantView

  def render("index.json", %{entrant: entrant}) do
    %{data: render_many(entrant, EntrantView, "entrant.json")}
  end

  def render("show.json", %{entrant: entrant}) do
    %{data: render_one(entrant, EntrantView, "entrant.json")}
  end

  def render("entrant.json", %{entrant: entrant}) do
    %{id: entrant.id,
      rank: entrant.rank}
  end
end

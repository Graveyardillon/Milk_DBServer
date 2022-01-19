defmodule MilkWeb.TournamentTagView do
  use MilkWeb, :view
  alias MilkWeb.TournamentTagView

  def render("list.json", %{tags: tags}) do
    %{
      data: render_many(tags, TournamentTagView, "tag.json", as: :tag)
    }
  end

  def render("tag.json", %{tag: tag}) do
    %{ id: tag.id, name: tag.name }
  end
end

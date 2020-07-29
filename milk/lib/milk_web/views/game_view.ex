defmodule MilkWeb.GameView do
  use MilkWeb, :view
  alias MilkWeb.GameView

  def render("list.json", %{games: games}) do
    %{data: render_many(games, GameView, "game.json")}
  end

  def render("show.json", %{game: game}) do
    %{data: render_one(game, GameView, "game.json")}
  end

  def render("game.json", %{game: game}) do
    %{id: game.id,
      title: game.title,
      icon_path: game.icon_path}
  end
end

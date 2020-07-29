defmodule MilkWeb.ProfileView do
  use MilkWeb, :view
  alias MilkWeb.ProfileView
  alias MilkWeb.GameView

  def render("index.json", %{profiles: profiles}) do
    %{data: render_many(profiles, ProfileView, "profile.json")}
  end

  def render("show.json", %{profile: profile}) do
    %{data: render_one(profile, ProfileView, "profile.json")}
  end

  def render("profile.json", %{profile: profile}) do
    %{id: profile.id,
      user_id: profile.user_id,
      content_id: profile.content_id,
      content_type: profile.content_type}
  end

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

defmodule MilkWeb.ProfileView do
  use MilkWeb, :view
  alias MilkWeb.ProfileView
  alias MilkWeb.GameView
  alias MilkWeb.AchievementView

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

  def render("profile.json", %{user: user, games: games, achievements: achievements}) do
    %{
      id: user.id,
      name: user.name,
      bio: user.bio,
      gameList: render_many(games, GameView, "game.json"),
      achievementList: render_many(achievements, AchievementView, "achievement.json")
    }
  end
end

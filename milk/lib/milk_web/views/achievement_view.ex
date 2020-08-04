defmodule MilkWeb.AchievementView do
  use MilkWeb, :view
  alias MilkWeb.AchievementView

  def render("list.json", %{achievements: achievements}) do
    %{data: render_many(achievements, AchievementView, "achievement.json")}
  end

  def render("show.json", %{achievement: achievement}) do
    %{data: render_one(achievement, AchievementView, "achievement.json")}
  end

  def render("achievement.json", %{achievement: achievement}) do
    %{id: achievement.id,
      user_id: achievement.user_id,
      title: achievement.title,
      icon_path: achievement.icon_path}
  end
end

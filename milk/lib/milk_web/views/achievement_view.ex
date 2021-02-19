defmodule MilkWeb.AchievementView do
  use MilkWeb, :view
  alias MilkWeb.AchievementView
  alias MilkWeb.TournamentView

  def render("list.json", %{achievements: achievements}) do
    %{data: render_many(achievements, AchievementView, "achievement.json")}
  end

  def render("show.json", %{achievement: achievement}) do
    %{data: render_one(achievement, AchievementView, "achievement.json")}
  end

  def render("achievement.json", %{achievement: achievement}) do
    %{
      tournament: render_one(achievement.tournament, TournamentView, "tournament.json"),
      rank: achievement.rank
    }
  end

  # def render("error.json", %{list: list}) do
  #   %{data: render_many(list, AchievementView, "errors.json")}
  # end

  # def render("errors.json", error) do
  #   %{error: error}
  # end

  # def render("delete.json", achievement) do
  #   %{data:
  #     %{
  #       title: achievement.achievement.title,
  #       id: achievement.achievement.id,
  #       user_id: achievement.achievement.user_id
  #     }
  #   }
  # end
end

defmodule MilkWeb.AchievementController do
  use MilkWeb, :controller

  alias Milk.Achievements
  alias Milk.Achievements.Achievement
  alias Milk.Accounts

  action_fallback MilkWeb.FallbackController

  def show(conn, %{"user_id" => user_id}) do
    user = Accounts.get_user(user_id)
    achievements = Achievements.get_achievement(user)
    conn |> render("list.json", achievements: achievements)
  end

  def add(conn, %{"achievement" => achievement_params}) do
    user = Accounts.get_user(achievement_params["user_id"])
    with {:ok, %Achievement{} = achievement} <- Achievements.add_achievement(user, achievement_params) do
      conn |> render("show.json", achievement: achievement)
    end
  end

end

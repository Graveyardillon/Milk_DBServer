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

  def show_one(conn, %{"id" => id}) do
    achievement = Achievements.get_achievement!(id)
    conn |> render("show.json", achievement: achievement)
  end

  def create(conn, %{"achievement" => achievement_params}) do
    
      case achievement_params["user_id"] do
        nil -> render(conn, "error.json",list: ["user does not exist"])
        id ->
          user = Accounts.get_user(id)
          with {:ok, %Achievement{} = achievement} <- Achievements.add_achievement(user, achievement_params) do
            conn |> render("show.json", achievement: achievement)
          end
      end

  end

  def update(conn, params) do
      Achievements.get_achievement!(params["id"])
      |> Achievements.update_achievement(params["attrs"])
      |> case do
        {:ok, updated} -> render(conn, "show.json",achievement: updated)
        {:error, %Ecto.Changeset{} = error} ->
          error_list =
            Enum.map(error.errors, fn x ->
              case x do
                {:user_id, {"can't be blank", [validation: :required]}} -> "user_id can't be blank"
                {:title, {"can't be blank", [validation: :required]}} -> "title can't be blank"
                {:icon_path, {"can't be blank", [validation: :required]}} -> "icon_path can't be blank"
              end
            end)
          render(conn, "error.json", list: error_list)
      end
  end

  def index(conn, params) do
    render(conn, "list.json", achievements: params)
  end

  def delete(conn, params) do
    {:ok, deleted} = Achievements.delete_achievement(params)
    render(conn, "delete.json", achievement: deleted)
  end
end

defmodule MilkWeb.ProfileController do
  use MilkWeb, :controller

  alias Milk.Accounts
  alias Milk.Profiles
  alias Milk.Accounts.Profile
  alias Milk.Games

  action_fallback MilkWeb.FallbackController

  def add(conn, %{"data" => data_params}) do
    case Profiles.check_duplication(data_params) do
      {:ok} ->
        with {:ok, %Profile{} = profile} <- Profiles.add(data_params) do
          conn
          |> render("show.json", profile: profile)
        end
      {:error} ->
        conn |> json%{msg: "already added!"}
    end

  end

  def fav_games(conn, %{"user_id" => user_id}) do
    id_list = Profiles.get_id_list_game(user_id)
    games = Games.get_games_by_id_list(id_list)

    render(conn, "list.json", games: games)
  end

  def delete_game(conn, %{"user_id" => user_id, "content_id" => game_id}) do
    conn |> delete_replay(Profiles.delete_game(user_id, game_id))
  end
  def delete_achievement(conn, %{"user_id" => user_id, "content_id" => achievement_id}) do
    conn |> delete_replay(Profiles.delete_game(user_id, achievement_id))
  end

  defp delete_replay(conn, {:not_found}) do
    conn |> json%{msg: "not found"}
  end
  defp delete_replay(conn, {:found}) do
    conn |> json%{msg: "deleted!"}
  end
  # def index(conn, _params) do
  #   profiles = Accounts.list_profiles()
  #   render(conn, "index.json", profiles: profiles)
  # end

  # def create(conn, %{"profile" => profile_params}) do
  #   with {:ok, %Profile{} = profile} <- Accounts.create_profile(profile_params) do
  #     conn
  #     |> put_status(:created)
  #     |> put_resp_header("location", Routes.profile_path(conn, :show, profile))
  #     |> render("show.json", profile: profile)
  #   end
  # end

  # def show(conn, %{"id" => id}) do
  #   profile = Accounts.get_profile!(id)
  #   render(conn, "show.json", profile: profile)
  # end

  # def update(conn, %{"id" => id, "profile" => profile_params}) do
  #   profile = Accounts.get_profile!(id)

  #   with {:ok, %Profile{} = profile} <- Accounts.update_profile(profile, profile_params) do
  #     render(conn, "show.json", profile: profile)
  #   end
  # end

  # def delete(conn, %{"id" => id}) do
  #   profile = Accounts.get_profile!(id)

  #   with {:ok, %Profile{}} <- Accounts.delete_profile(profile) do
  #     send_resp(conn, :no_content, "")
  #   end
  # end
end

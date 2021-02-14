defmodule MilkWeb.ProfileController do
  use MilkWeb, :controller

  alias Milk.Accounts
  alias Milk.Profiles
  alias Milk.CloudStorage.Objects

  action_fallback MilkWeb.FallbackController

  def get_profile(conn, %{"user_id" => user_id}) do
    user = Accounts.get_user(user_id)
    if user do
      games = Profiles.get_game_list(user)
      achievements = Profiles.get_achievement_list(user)

      render(conn, "profile.json", user: user, games: games, achievements: achievements)
    else
      json(conn, %{result: false, error: "user not found"})
    end
  end

  def update(conn, %{"profile" => profile_params}) do
    user =
      Map.get(profile_params, "user_id")
      |> Accounts.get_user()

    if user do
      name = Map.get(profile_params, "name")
      bio = Map.get(profile_params, "bio")
      gameList = Map.get(profile_params, "gameList")
      achievementList = Map.get(profile_params, "achievementList")

      Profiles.update_profile(user, name, bio, gameList, achievementList)
      json(conn, %{result: true})
    else
      json(conn, %{result: false, error: "user not found"})
    end
  end

  def update_icon(conn, %{"user_id" => user_id, "image" => image}) do
    user = Accounts.get_user(user_id)
    if user do
      uuid = SecureRandom.uuid()

      File.cp(image.path, "./static/image/profile_icon/#{uuid}.png")
      local_path = case Application.get_env(:milk, :environment) do
        :dev -> update_account(user, uuid)
        :test -> update_account(user, uuid)
        _ -> update_account_prod(user, uuid)
      end
      json(conn, %{local_path: local_path})
    else
      json(conn, %{error: "user not found"})
    end
  end

  defp update_account(user, uuid) do
    Accounts.update_icon_path(user, "./static/image/profile_icon/#{uuid}.png")
    uuid
  end

  defp update_account_prod(user, uuid) do
    object = Objects.upload("./static/image/profile_icon/#{uuid}.png")
    File.rm("./static/image/profile_icon/#{uuid}.png")
    Accounts.update_icon_path(user, object)
    object.name
  end

  def get_icon(conn, %{"path" => path}) do
    if path != "" do
      case File.read(path) do
        {:ok, file} ->
          b64 = Base.encode64(file)
          json(conn, %{b64: b64})
        {:error, _} ->
          json(conn, %{error: "image not found"})
      end
    else
      json(conn, %{error: "path nil"})
    end
  end
end

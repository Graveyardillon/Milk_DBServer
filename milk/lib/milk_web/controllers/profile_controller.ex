defmodule MilkWeb.ProfileController do
  use MilkWeb, :controller

  alias Milk.Accounts
  alias Milk.Accounts.User
  alias Milk.Profiles
  alias Milk.Accounts.Profile
  alias Milk.Games

  action_fallback MilkWeb.FallbackController

  def get_profile(conn, %{"user_id" => user_id}) do
    user = Accounts.get_user(user_id)
    games = Profiles.get_game_list(user)
    achievements = Profiles.get_achievement_list(user)

    render(conn, "profile.json", user: user, games: games, achievements: achievements)
  end

  def update(conn, %{"profile" => profile_params}) do
    user_id = Map.get(profile_params, "user_id")
    name = Map.get(profile_params, "name")
    bio = Map.get(profile_params, "bio")
    gameList = Map.get(profile_params, "gameList")
    achievementList = Map.get(profile_params, "achievementList")

    Profiles.update_profile(Accounts.get_user(user_id), name, bio, gameList, achievementList)
    json(conn, %{result: "success"})
  end

  def update_icon(conn, %{"user_id" => user_id, "image_b64" => image_b64}) do

    user = Accounts.get_user(user_id)
    IO.puts(user.icon_path)

    if String.starts_with?(image_b64, "data:image/png;base64,") do
      "data:image/png;base64," <> raw = image_b64
      uuid = SecureRandom.uuid()
      File.write!("./static/image/profile_icon/#{uuid}.png", Base.decode64!(raw))

      json(conn, %{local_path: uuid})
    else
      raw = image_b64
      uuid = SecureRandom.uuid()
      File.write!("./static/image/profile_icon/#{uuid}.png", Base.decode64!(raw))

      Accounts.update_icon_path(user, uuid)

      json(conn, %{local_path: uuid})
    end
  end

  def get_icon(conn, %{"path" => path}) do
    b64 = File.read!("./static/image/profile_icon/#{path}.png")
          |> Base.encode64()

    json(conn, %{b64: b64})
  end

end

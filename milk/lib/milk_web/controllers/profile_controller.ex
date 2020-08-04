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

    render(conn, "profile.json", user: user, games: games)
  end

  def update(conn, %{"profile" => profile_params}) do
    user_id = Map.get(profile_params, "user_id")
    name = Map.get(profile_params, "name")
    bio = Map.get(profile_params, "bio")
    gameList = Map.get(profile_params, "gameList")

    Profiles.update_profile(Accounts.get_user(user_id), name, bio, gameList)
    json(conn, %{result: "success"})
  end

end

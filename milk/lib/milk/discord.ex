defmodule Milk.Discord do
  @moduledoc """
  The Discord context.
  """

  alias Milk.Discord.User, as: DiscordUser

  import Common.Sperm

  alias Milk.{
    Repo,
    Tournaments
  }

  import Ecto.Query, warn: false

  @doc """
  Get discord user by user id
  """
  def get_discord_user_by_user_id(user_id) do
    DiscordUser
    |> where([du], du.user_id == ^user_id)
    |> Repo.one()
  end

  @doc """
  Get discord user by user id and discord id
  """
  def get_discord_user_by_user_id_and_discord_id(user_id, discord_id) do
    DiscordUser
    |> where([du], du.user_id == ^user_id)
    |> where([du], du.discord_id == ^discord_id)
    |> Repo.one()
  end

  @doc """
  Validate the all team members are associated with discord.
  """
  def all_team_members_associated?(team_id) do
    team_id
    |> Tournaments.get_team_members_by_team_id()
    |> Enum.all?(fn member ->
      member
      |> Map.get(:user_id)
      |> associated?()
    end)
  end

  @doc """
  Create a disord user (user who is associated with discord)
  """
  def create_discord_user(attrs) do
    %DiscordUser{}
    |> DiscordUser.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Checks the given user has associated with discord.
  """
  def associated?(user_id) do
    DiscordUser
    |> where([du], du.user_id == ^user_id)
    |> Repo.exists?()
  end

  @doc """
  associate with discord.
  """
  def associate(user_id, discord_id) do
    discord_user = get_discord_user_by_user_id_and_discord_id(user_id, discord_id)

    cond do
      !is_nil(discord_user) ->
        {:error, "already associated"}

      associated?(user_id) ->
        user_id
        |> get_discord_user_by_user_id()
        |> update_discord_user(%{discord_id: discord_id})

      true ->
        Map.new()
        |> Map.put(:user_id, user_id)
        |> Map.put(:discord_id, discord_id)
        |> create_discord_user()
    end
  end

  @doc """
  update discord user.
  """
  def update_discord_user(%DiscordUser{} = discord_user, attrs) do
    discord_user
    |> DiscordUser.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Delete discord user.
  """
  def delete_discord_user(%DiscordUser{} = discord_user) do
    Repo.delete(discord_user)
  end

  def create_invitation_link!(server_id) do
    access_token = Application.get_env(:milk, :discord_server_access_token)
    url = "#{Application.get_env(:milk, :discord_server)}/invitation_link"

    params = Jason.encode!(%{server_id: server_id, access_token: access_token})
      |> IO.inspect(label: :params_in_create_invitation_link)

    url
    |> IO.inspect(label: :url_in_create_invitation_link!)
    |> HTTPoison.post(params, "Content-Type": "application/json")
    |> IO.inspect(label: :create_invitation_link)
    |> case do
      {:ok, response} ->
        response
        |> Map.get(:body)
        |> Jason.decode()
        |> elem(1)
        |> Map.get("url")

      {:error, error} ->
        raise "Failed to get invitation link, #{error}"
    end
  end

  # Discord server 通知周り

  @doc """
  Send notification on tournament start.
  """
  def send_tournament_start_notification(server_id) when is_binary(server_id) do
    discord_server_url = Application.get_env(:milk, :discord_server)
    access_token = Application.get_env(:milk, :discord_server_access_token)

    url = "#{discord_server_url}/tournament_start"
    params = Jason.encode!(%{server_id: server_id, access_token: access_token})

    HTTPoison.post(url, params, "Content-Type": "application/json")
  end

  def send_tournament_start_notification(_) do
    {:error, "need to provide server id in binary format."}
  end

  @doc """
  Send notification on added team to the server
  """
  def send_tournament_add_team_notification(server_id, team_name) when is_binary(server_id) do
    discord_server_url = Application.get_env(:milk, :discord_server)
    access_token = Application.get_env(:milk, :discord_server_access_token)

    url = "#{discord_server_url}/add_team"

    Map.new()
    |> Map.put(:server_id, server_id)
    |> Map.put(:access_token, access_token)
    |> Map.put(:team_name, team_name)
    |> Jason.encode!()
    ~> params

    HTTPoison.post(url, params, "Content-Type": "application/json")
  end

  def send_tournament_add_team_notification(_, _) do
    {:error, "need to provide server id in binary format."}
  end

  @doc """
  Send notification on start match
  """
  def send_tournament_start_match_notification(server_id, a_name, b_name)
      when is_binary(server_id) do
    discord_server_url = Application.get_env(:milk, :discord_server)
    access_token = Application.get_env(:milk, :discord_server_access_token)

    url = "#{discord_server_url}/start_match"

    Map.new()
    |> Map.put(:server_id, server_id)
    |> Map.put(:access_token, access_token)
    |> Map.put(:team_a_name, a_name)
    |> Map.put(:team_b_name, b_name)
    |> Jason.encode!()
    ~> params

    HTTPoison.post(url, params, "Content-Type": "application/json")
  end

  def send_tournament_start_match_notification(_, _, _) do
    {:error, "need to provide server id in binary format."}
  end

  @doc """
  Send notification on ban maps.
  """
  def send_tournament_ban_map_notification(server_id, a_name, b_name, banned_map_names)
      when is_binary(server_id) and is_list(banned_map_names) do
    discord_server_url = Application.get_env(:milk, :discord_server)
    access_token = Application.get_env(:milk, :discord_server_access_token)

    url = "#{discord_server_url}/ban_maps"

    Map.new()
    |> Map.put(:server_id, server_id)
    |> Map.put(:access_token, access_token)
    |> Map.put(:a_name, a_name)
    |> Map.put(:b_name, b_name)
    |> Map.put(:banned_map_names, banned_map_names)
    |> Jason.encode!()
    ~> params

    HTTPoison.post(url, params, "Content-Type": "application/json")
  end

  def send_tournament_ban_map_notification(_, _, _, _) do
    {:error, "need to provide server id in binary format and banned map names in list."}
  end

  @doc """
  Send notification on choose maps.
  """
  def send_tournament_choose_map_notification(server_id, a_name, b_name, map_name)
      when is_binary(server_id) do
    discord_server_url = Application.get_env(:milk, :discord_server)
    access_token = Application.get_env(:milk, :discord_server_access_token)

    url = "#{discord_server_url}/choose_map"

    Map.new()
    |> Map.put(:server_id, server_id)
    |> Map.put(:access_token, access_token)
    |> Map.put(:a_name, a_name)
    |> Map.put(:b_name, b_name)
    |> Map.put(:map_name, map_name)
    |> Jason.encode!()
    ~> params

    HTTPoison.post(url, params, "Content-Type": "application/json")
  end

  def send_tournament_choose_map_notification(_, _, _, _) do
    {:error, "need to provide server id in binary format."}
  end

  @doc """
  Send notification on choose a/d
  """
  def send_tournament_choose_ad_notification(server_id, a_name, b_name, is_attacker_side)
      when is_binary(server_id) do
    discord_server_url = Application.get_env(:milk, :discord_server)
    access_token = Application.get_env(:milk, :discord_server_access_token)

    url = "#{discord_server_url}/choose_ad"

    Map.new()
    |> Map.put(:server_id, server_id)
    |> Map.put(:access_token, access_token)
    |> Map.put(:a_name, a_name)
    |> Map.put(:b_name, b_name)
    |> Map.put(:is_attacker_side, is_attacker_side)
    |> Jason.encode!()
    ~> params

    HTTPoison.post(url, params, "Content-Type": "application/json")
  end

  def send_tournament_choose_ad_notification(_, _, _, _) do
    {:error, "need to provide server id in binary format."}
  end

  @doc """
  Send notification on duplication claim.
  """
  def send_tournament_duplicate_claim_notification(server_id, a_name, b_name, score)
      when is_binary(server_id) do
    discord_server_url = Application.get_env(:milk, :discord_server)
    access_token = Application.get_env(:milk, :discord_server_access_token)

    url = "#{discord_server_url}/duplicate_claim"

    Map.new()
    |> Map.put(:server_id, server_id)
    |> Map.put(:access_token, access_token)
    |> Map.put(:a_name, a_name)
    |> Map.put(:b_name, b_name)
    |> Map.put(:score, score)
    |> Jason.encode!()
    ~> params

    HTTPoison.post(url, params, "Content-Type": "application/json")
  end

  def send_tournament_duplicate_claim_notification(_, _, _, _) do
    {:error, "need to provide server id in binary format."}
  end

  @doc """
  Send notification on finish match.
  """
  def send_tournament_finish_match_notification(server_id, a_name, b_name, a_score, b_score)
      when is_binary(server_id) do
    unless is_nil(server_id) do
      discord_server_url = Application.get_env(:milk, :discord_server)
      access_token = Application.get_env(:milk, :discord_server_access_token)

      url = "#{discord_server_url}/finish_match"

      Map.new()
      |> Map.put(:server_id, server_id)
      |> Map.put(:access_token, access_token)
      |> Map.put(:team_a_name, a_name)
      |> Map.put(:team_b_name, b_name)
      |> Map.put(:team_a_score, a_score)
      |> Map.put(:team_b_score, b_score)
      |> Jason.encode!()
      ~> params

      HTTPoison.post(url, params, "Content-Type": "application/json")
    end
  end

  def send_tournament_finish_match_notification(_, _, _, _, _) do
    {:error, "need to provide server id in binary format."}
  end

  @doc """
  Sending notification on tournament finish
  """
  def send_tournament_finish_notification(server_id, tournament_name, winner_name)
      when is_binary(server_id) do
    discord_server_url = Application.get_env(:milk, :discord_server)
    access_token = Application.get_env(:milk, :discord_server_access_token)

    url = "#{discord_server_url}/finish_tournament"

    Map.new()
    |> Map.put(:server_id, server_id)
    |> Map.put(:access_token, access_token)
    |> Map.put(:tournament_name, tournament_name)
    |> Map.put(:winner_name, winner_name)
    |> Jason.encode!()
    ~> params

    HTTPoison.post(url, params, "Content-Type": "application/json")
  end

  def send_tournament_finish_notification(_, _, _) do
    {:error, "need to provide server id in binary format."}
  end

  @doc """
  Sending notification on tournament delete
  """
  def send_tournament_delete_notification(server_id) when is_binary(server_id) do
    discord_server_url = Application.get_env(:milk, :discord_server)
    access_token = Application.get_env(:milk, :discord_server_access_token)

    url = "#{discord_server_url}/delete_tournament"

    Map.new()
    |> Map.put(:server_id, server_id)
    |> Map.put(:access_token, access_token)
    |> Jason.encode!()
    ~> params

    HTTPoison.post(url, params, "Content-Type": "application/json")
  end

  def send_tournament_delete_notification(_) do
    {:error, "need to provide server id in binary format."}
  end
end

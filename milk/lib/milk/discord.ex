defmodule Milk.Discord do
  @moduledoc """
  The Discord context.
  """

  import Common.Sperm

  alias Milk.Discord.User, as: DiscordUser

  alias Milk.{
    Repo,
    Tournaments
  }

  import Ecto.Query, warn: false

  @doc """
  Get discord user by user id
  """
  @spec get_discord_user_by_user_id(integer()) :: DiscordUser.t() | nil
  def get_discord_user_by_user_id(user_id) do
    DiscordUser
    |> where([du], du.user_id == ^user_id)
    |> Repo.one()
  end

  @doc """
  Get discord user by user id and discord id
  """
  @spec get_discord_user_by_user_id_and_discord_id(integer(), String.t()) :: DiscordUser.t() | nil
  def get_discord_user_by_user_id_and_discord_id(user_id, discord_id) do
    DiscordUser
    |> where([du], du.user_id == ^user_id)
    |> where([du], du.discord_id == ^discord_id)
    |> Repo.one()
  end

  @doc """
  Validate the all team members are associated with discord.
  """
  @spec all_team_members_associated?(integer()) :: boolean()
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
  @spec create_discord_user(map()) :: {:ok, DiscordUser.t()} | {:error, Ecto.Changeset.t()}
  def create_discord_user(attrs) do
    %DiscordUser{}
    |> DiscordUser.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Checks the given user has associated with discord.
  """
  @spec associated?(integer()) :: boolean()
  def associated?(user_id) do
    DiscordUser
    |> where([du], du.user_id == ^user_id)
    |> Repo.exists?()
  end

  @doc """
  associate with discord.
  """
  @spec associate(integer(), String.t()) :: {:ok, DiscordUser.t()} | {:error, Ecto.Changeset.t()}
  def associate(user_id, discord_id) do
    discord_user = get_discord_user_by_user_id_and_discord_id(user_id, discord_id)

    cond do
      !is_nil(discord_user) ->
        {:error, "already associated"}

      __MODULE__.associated?(user_id) ->
        user_id
        |> __MODULE__.get_discord_user_by_user_id()
        |> __MODULE__.update_discord_user(%{discord_id: discord_id})

      :else ->
        Map.new()
        |> Map.put(:user_id, user_id)
        |> Map.put(:discord_id, discord_id)
        |> __MODULE__.create_discord_user()
    end
  end

  @doc """
  update discord user.
  """
  @spec update_discord_user(DiscordUser.t(), map()) ::
          {:ok, DiscordUser.t()} | {:error, Ecto.Changeset.t()}
  def update_discord_user(%DiscordUser{} = discord_user, attrs) do
    discord_user
    |> DiscordUser.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Delete discord user.
  """
  @spec delete_discord_user(DiscordUser.t()) ::
          {:ok, DiscordUser.t()} | {:error, Ecto.Changeset.t()}
  def delete_discord_user(%DiscordUser{} = discord_user) do
    Repo.delete(discord_user)
  end

  @spec create_invitation_link!(String.t()) :: String.t()
  def create_invitation_link!(server_id) do
    access_token = Application.get_env(:milk, :discord_server_access_token)
    url = "#{Application.get_env(:milk, :discord_server)}/invitation_link"

    params = Jason.encode!(%{server_id: server_id, access_token: access_token})

    url
    |> HTTPoison.post(params, "Content-Type": "application/json", timeout: 5000, recv_timeout: 10000)
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

  @spec send_tournament_create_notification(String.t()) :: {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}
  def send_tournament_create_notification(server_id) when is_binary(server_id) do
    discord_server_url = Application.get_env(:milk, :discord_server)
    access_token = Application.get_env(:milk, :discord_server_access_token)

    url = "#{discord_server_url}/create_tournament"
    params = Jason.encode!(%{server_id: server_id, access_token: access_token})

    HTTPoison.post(url, params, "Content-Type": "application/json")
  end

  @spec send_tournament_description(String.t(), String.t()) :: {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}
  def send_tournament_description(server_id, description)
      when is_binary(server_id) and is_binary(description) do
    discord_server_url = Application.get_env(:milk, :discord_server)
    access_token = Application.get_env(:milk, :discord_server_access_token)

    url = "#{discord_server_url}/description"

    params = Jason.encode!(%{server_id: server_id, access_token: access_token, description: description})

    HTTPoison.post(url, params, "Content-Type": "application/json", timeout: 5000, recv_timeout: 10000)
  end

  ### Discord server 通知周りの関数群

  @doc """
  Send notification on tournament start.
  """
  @spec send_tournament_start_notification(String.t()) :: {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}
  def send_tournament_start_notification(server_id) when is_binary(server_id) do
    discord_server_url = Application.get_env(:milk, :discord_server)
    access_token = Application.get_env(:milk, :discord_server_access_token)

    url = "#{discord_server_url}/tournament_start"
    params = Jason.encode!(%{server_id: server_id, access_token: access_token})

    HTTPoison.post(url, params, "Content-Type": "application/json", timeout: 5000, recv_timeout: 10000)
  end

  def send_tournament_start_notification(_) do
    {:error, "need to provide server id in binary format."}
  end

  @doc """
  Send notification on added team to the server
  """
  @spec send_tournament_add_team_notification(String.t(), String.t()) :: {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}
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

    HTTPoison.post(url, params, "Content-Type": "application/json", timeout: 5000, recv_timeout: 10000)
  end

  def send_tournament_add_team_notification(_, _) do
    {:error, "need to provide server id in binary format."}
  end

  @spec send_tournament_remove_team_notification(String.t(), String.t()) :: {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t() | String.t()}
  def send_tournament_remove_team_notification(server_id, team_name) when is_binary(server_id) do
    discord_server_url = Application.get_env(:milk, :discord_server)
    access_token = Application.get_env(:milk, :discord_server_access_token)

    url = "#{discord_server_url}/remove_team"

    %{}
    |> Map.put(:server_id, server_id)
    |> Map.put(:access_token, access_token)
    |> Map.put(:team_name, team_name)
    |> Jason.encode!()
    ~> params

    HTTPoison.post(url, params, "Content-Type": "application/json", timeout: 5000, recv_timeout: 10000)
  end

  def send_tournament_remove_team_notification(_, _) do
    {:error, "need to provide server id in binary format."}
  end

  @doc """
  Send notification on start match
  """
  @spec send_tournament_start_match_notification(String.t(), String.t(), String.t()) :: {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}
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

    HTTPoison.post(url, params, "Content-Type": "application/json", timeout: 5000, recv_timeout: 10000)
  end

  def send_tournament_start_match_notification(_, _, _) do
    {:error, "need to provide server id in binary format."}
  end

  @doc """
  Send notification on ban maps.
  """
  @spec send_tournament_ban_map_notification(String.t(), String.t(), String.t(), [String.t()]) :: {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}
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

    HTTPoison.post(url, params, "Content-Type": "application/json", timeout: 5000, recv_timeout: 10000)
  end

  def send_tournament_ban_map_notification(_, _, _, _) do
    {:error, "need to provide server id in binary format and banned map names in list."}
  end

  @doc """
  Send notification on choose maps.
  """
  @spec send_tournament_choose_map_notification(String.t(), String.t(), String.t(), String.t()) :: {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}
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

    HTTPoison.post(url, params, "Content-Type": "application/json", timeout: 5000, recv_timeout: 10000)
  end

  def send_tournament_choose_map_notification(_, _, _, _) do
    {:error, "need to provide server id in binary format."}
  end

  @doc """
  Send notification on choose a/d
  """
  @spec send_tournament_choose_ad_notification(String.t(), String.t(), String.t(), boolean()) :: {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}
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

    HTTPoison.post(url, params, "Content-Type": "application/json", timeout: 5000, recv_timeout: 10000)
  end

  def send_tournament_choose_ad_notification(_, _, _, _) do
    {:error, "need to provide server id in binary format."}
  end

  @doc """
  Send notification on duplication claim.
  """
  @spec send_tournament_duplicate_claim_notification(String.t(), String.t(), String.t(), integer()) :: {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}
  def send_tournament_duplicate_claim_notification(server_id, a_name, b_name, score) when is_binary(server_id) do
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

    HTTPoison.post(url, params, "Content-Type": "application/json", timeout: 5000, recv_timeout: 10000)
  end

  def send_tournament_duplicate_claim_notification(_, _, _, _) do
    {:error, "need to provide server id in binary format."}
  end

  @doc """
  Send notification on finish match.
  """
  @spec send_tournament_finish_match_notification(
          String.t(),
          String.t(),
          String.t(),
          integer(),
          integer()
        ) :: {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}
  def send_tournament_finish_match_notification(server_id, a_name, b_name, a_score, b_score)
      when is_binary(server_id) do
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

    HTTPoison.post(url, params, "Content-Type": "application/json", timeout: 5000, recv_timeout: 10000)
  end

  def send_tournament_finish_match_notification(_, _, _, _, _) do
    {:error, "need to provide server id in binary format."}
  end

  @doc """
  Sending notification on tournament finish
  """
  @spec send_tournament_finish_notification(String.t(), String.t(), String.t()) ::
          {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}
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

    HTTPoison.post(url, params, "Content-Type": "application/json", timeout: 5000, recv_timeout: 10000)
  end

  def send_tournament_finish_notification(_, _, _) do
    {:error, "need to provide server id in binary format."}
  end

  @doc """
  Sending notification on tournament delete
  """
  @spec send_tournament_delete_notification(String.t()) ::
          {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}
  def send_tournament_delete_notification(server_id) when is_binary(server_id) do
    discord_server_url = Application.get_env(:milk, :discord_server)
    access_token = Application.get_env(:milk, :discord_server_access_token)

    url = "#{discord_server_url}/delete_tournament"

    Map.new()
    |> Map.put(:server_id, server_id)
    |> Map.put(:access_token, access_token)
    |> Jason.encode!()
    ~> params

    HTTPoison.post(url, params, "Content-Type": "application/json", timeout: 5000, recv_timeout: 10000)
  end

  def send_tournament_delete_notification(_) do
    {:error, "need to provide server id in binary format."}
  end
end

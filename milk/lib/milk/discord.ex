defmodule Milk.Discord do
  @moduledoc """
  The Discord context.
  """

  alias Milk.Discord.User, as: DiscordUser

  alias Milk.{
    Accounts,
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
    |> Enum.map(fn member ->
      member
      |> Map.get(:user_id)
      |> Accounts.get_user()
      |> IO.inspect()
      |> Map.get(:discord)
    end)
    |> IO.inspect()
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
end

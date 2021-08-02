defmodule Milk.Profiles do
  import Ecto.Query, warn: false

  alias Milk.Accounts.{
    Profile,
    User
  }

  alias Milk.Games.Game

  alias Milk.Log.{
    EntrantLog,
    TournamentLog
  }

  alias Milk.Repo

  @doc """
  Returns the list of profiles.

  ## Examples

      iex> list_profiles()
      [%Profile{}, ...]

  """
  def list_profiles do
    Repo.all(Profile)
  end

  @doc """
  Gets a single profile.

  Raises `Ecto.NoResultsError` if the Profile does not exist.

  ## Examples

      iex> get_profile!(123)
      %Profile{}

      iex> get_profile!(456)
      ** (Ecto.NoResultsError)

  """
  def get_profile!(id), do: Repo.get!(Profile, id)

  @doc """
  Creates a profile.

  ## Examples

      iex> create_profile(%{field: value})
      {:ok, %Profile{}}

      iex> create_profile(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_profile(attrs \\ %{}) do
    %Profile{}
    |> Profile.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a profile.

  ## Examples

      iex> update_profile(profile, %{field: new_value})
      {:ok, %Profile{}}

      iex> update_profile(profile, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_profile(%Profile{} = profile, attrs) do
    profile
    |> Profile.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a profile.

  ## Examples

      iex> delete_profile(profile)
      {:ok, %Profile{}}

      iex> delete_profile(profile)
      {:error, %Ecto.Changeset{}}

  """
  def delete_profile(%Profile{} = profile) do
    Repo.delete(profile)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking profile changes.

  ## Examples

      iex> change_profile(profile)
      %Ecto.Changeset{data: %Profile{}}

  """
  def change_profile(%Profile{} = profile, attrs \\ %{}) do
    Profile.changeset(profile, attrs)
  end

  def get_game_list(user) do
    ids =
      Profile
      |> where([p], p.user_id == ^user.id and p.content_type == "game")
      |> Repo.all()
      |> Enum.map(& &1.content_id)

    Game
    |> where([g], g.id in ^ids)
    |> Repo.all()
  end

  @doc """
  Get added records of the user.
  """
  def get_records(user) do
    ids =
      Profile
      |> where([p], p.user_id == ^user.id and p.content_type == "record")
      |> Repo.all()
      |> Enum.map(& &1.content_id)

    EntrantLog
    |> where([el], el.tournament_id in ^ids and el.user_id == ^user.id)
    |> Repo.all()
    |> Enum.map(fn entrant_log ->
      tlog =
        TournamentLog
        |> where([tl], tl.tournament_id == ^entrant_log.tournament_id)
        |> Repo.one()

      Map.put(entrant_log, :tournament_log, tlog)
    end)
    |> Enum.filter(fn entrant_log -> entrant_log.tournament_log != nil end)
  end

  def update_profile(%User{} = user, name, bio) do
    user
    |> User.changeset(%{name: name, bio: bio})
    |> Repo.update()
  end

  def update_gamelist(%User{} = user, gameList) do
    Profile
    |> where([p], p.user_id == ^user.id)
    |> where([p], p.content_type == "game")
    |> Repo.delete_all()

    Enum.each(gameList, fn game ->
      %Profile{}
      |> Profile.changeset(%{user_id: user.id, content_id: game, content_type: "game"})
      |> Repo.insert()
    end)
  end

  def update_recordlist(%User{} = user, recordlist) do
    Profile
    |> where([p], p.user_id == ^user.id)
    |> where([p], p.content_type == "record")
    |> Repo.delete_all()

    Enum.each(recordlist, fn record ->
      %Profile{}
      |> Profile.changeset(%{user_id: user.id, content_id: record, content_type: "record"})
      |> Repo.insert()
    end)
  end
end

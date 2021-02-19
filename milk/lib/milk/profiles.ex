defmodule Milk.Profiles do
  
  import Ecto.Query, warn: false
  alias Milk.Repo

  alias Milk.Accounts.User

  alias Milk.Games.Game
  alias Milk.Achievements.Achievement
  alias Milk.Accounts.Profile
  alias Milk.Tournaments.Entrant

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
    ids = Profile
    |> where([p], p.user_id == ^user.id and p.content_type == "game")
    |> Repo.all()
    |> Enum.map(& &1.content_id)

    Game
    |> where([g], g.id in ^ids)
    |> Repo.all
  end

  def get_achievement_list(user) do
    ids = Profile
    |> where([p], p.user_id == ^user.id and p.content_type == "achievement")
    |> Repo.all()
    |> Enum.map(& &1.content_id)

    Entrant
    |> where([e], e.tournament_id in ^ids and e.user_id == ^user.id)
    |> Repo.all()
    |> Repo.preload(:tournament)
  end

  def update_profile(%User{} = user, name, bio, gameList, achievementList) do
    Repo.update(Ecto.Changeset.change user, name: name, bio: bio)
    Profile
    |> where([p], p.user_id == ^user.id)
    |> Repo.delete_all()

    Enum.each(gameList, fn game ->
      %Profile{}
      |> Profile.changeset(%{user_id: user.id, content_id: game, content_type: "game"})
      |> Repo.insert()
    end)
    Enum.each(achievementList, fn achievement ->
      %Profile{}
      |> Profile.changeset(%{user_id: user.id, content_id: achievement, content_type: "achievement"})
      |> Repo.insert()
    end)
  end
end

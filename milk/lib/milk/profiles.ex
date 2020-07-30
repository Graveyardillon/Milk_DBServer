defmodule Milk.Profiles do
  
  import Ecto.Query, warn: false
  alias Milk.Repo

  alias Milk.Profiles
  alias Ecto.Multi

  alias Milk.Accounts.Profile

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

  def add(attrs \\ %{}) do
    %Profile{}
    |> Profile.changeset(attrs)
    |> Repo.insert()
  end

  def get_id_list_game(user_id) do
    Profile
      |> where([p], p.user_id == ^user_id and p.content_type == "game")
      |> Repo.all()
      |> Enum.map(& &1.content_id)
  end
  def get_id_list_achievement(user_id) do
    Profile
      |> where([p], p.user_id == ^user_id and p.content_type == "achievement")
      |> Repo.all()
      |> Enum.map(& &1.content_id)
  end

  def delete_game(user_id, game_id) do
    query = from p in Profile, where: p.user_id == ^user_id and p.content_id == ^game_id and p.content_type == "game"

    if Repo.one(query) == nil do
      {:not_found}
    else
      Repo.delete_all(query)
      {:found}
    end
  end

  def delete_achievement(user_id, achievement_id) do
    query = from p in Profile, where: p.user_id == ^user_id and p.content_id == ^achievement_id and p.content_type == "achievement"

    if Repo.one(query) == nil do
      {:not_found}
    else
      Repo.delete_all(query)
      {:found}
    end
  end

end

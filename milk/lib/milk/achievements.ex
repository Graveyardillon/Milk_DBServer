defmodule Milk.Achievements do
  @moduledoc """
  The Achievements context.
  """

  import Ecto.Query, warn: false

  alias Milk.Repo

  alias Milk.Achievements.Achievement

  @doc """
  Gets a single achievement.

  Raises `Ecto.NoResultsError` if the Achievement does not exist.

  ## Examples

      iex> get_achievement_by_id(123)
      %Achievement{}

      iex> get_achievement_by_id(456)
      ** (Ecto.NoResultsError)

  """
  def get_achievement_by_id(id), do: Repo.get!(Achievement, id)

  @doc """
  Creates a achievement.

  ## Examples

      iex> create_achievement(%{field: value})
      {:ok, %Achievement{}}

      iex> create_achievement(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_achievement(attrs \\ %{}) do
    %Achievement{}
    |> Achievement.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a achievement.

  ## Examples

      iex> update_achievement(achievement, %{field: new_value})
      {:ok, %Achievement{}}

      iex> update_achievement(achievement, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_achievement(%Achievement{} = achievement, attrs) do
    achievement
    |> Achievement.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a achievement.

  ## Examples

      iex> delete_achievement(achievement)
      {:ok, %Achievement{}}

      iex> delete_achievement(achievement)
      {:error, %Ecto.Changeset{}}

  """
  def delete_achievement(%Achievement{} = achievement) do
    Repo.delete(achievement)
  end

  def add_achievement(user, attrs \\ %{}) do
    Ecto.build_assoc(user, :achievements, title: attrs["title"], icon_path: attrs["icon_path"])
    |> Repo.insert()
  end

  def get_achievement(user) do
    user |> Ecto.assoc(:achievements) |> Repo.all()
  end

end

defmodule Milk.Lives do
  @moduledoc """
  The Lives context.
  """

  import Ecto.Query, warn: false
  alias Milk.Repo

  alias Milk.Lives.Live
  alias Milk.Relations

  @doc """
  Returns the list of lives.

  ## Examples

      iex> list_lives()
      [%Live{}, ...]

  """
  def list_lives do
    Repo.all(Live)
  end

  @doc """
  Gets a single live.

  Raises `Ecto.NoResultsError` if the Live does not exist.

  ## Examples

      iex> get_live!(123)
      %Live{}

      iex> get_live!(456)
      ** (Ecto.NoResultsError)

  """
  def get_live!(id), do: Repo.get!(Live, id)

  @doc """
  Creates a live.

  ## Examples

      iex> create_live(%{field: value})
      {:ok, %Live{}}

      iex> create_live(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_live(attrs \\ %{}) do
    %Live{streamer_id: attrs["streamer_id"], tournament_id: attrs["tournament_id"]}
    |> IO.inspect
    |> Live.changeset(attrs)
    |> IO.inspect
    |> Repo.insert()
  end

  @doc """
  Updates a live.

  ## Examples

      iex> update_live(live, %{field: new_value})
      {:ok, %Live{}}

      iex> update_live(live, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_live(%Live{} = live, attrs) do
    live
    |> Live.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a live.

  ## Examples

      iex> delete_live(live)
      {:ok, %Live{}}

      iex> delete_live(live)
      {:error, %Ecto.Changeset{}}

  """
  def delete_live(%Live{} = live) do
    Repo.delete(live)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking live changes.

  ## Examples

      iex> change_live(live)
      %Ecto.Changeset{data: %Live{}}

  """
  def change_live(%Live{} = live, attrs \\ %{}) do
    Live.changeset(live, attrs)
  end

  @doc """
  Returns live home data.
  """
  def home(user_id) do
    user_id
    |> Relations.get_following_list()
    |> Enum.map(fn user -> 
      Live
      |> where([l], l.streamer_id == ^user.id)
      |> Repo.all()
    end)
  end
end

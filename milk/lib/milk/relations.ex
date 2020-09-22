defmodule Milk.Relations do
  alias Milk.Accounts.Relation
  alias Milk.Repo

  import Ecto.Query, warn: false

  require Logger

  @doc """
  Returns the list of relations.

  ## Examples

      iex> list_relations()
      [%Relation{}, ...]

  """
  def list_relations do
      Repo.all(Relation)
  end

  @doc """
  Gets a single relation.

  Raises `Ecto.NoResultsError` if the Relation does not exist.

  ## Examples

      iex> get_relation!(123)
      %Relation{}

      iex> get_relation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_relation!(id), do: Repo.get!(Relation, id)

  @doc """
  Gets relation by followee_id and follower_id.
  """
  # TODO: Need to use Multi
  def get_relation_ids(follower_id, followee_id) do
    Relation
    |> where([r], r.follower_id == ^follower_id)
    |> where([r], r.followee_id == ^followee_id)
    |> Repo.one()
  end

  @doc """
  Creates a relation.

  ## Examples

      iex> create_relation(%{field: value})
      {:ok, %Relation{}}

      iex> create_relation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  # TODO: エラーハンドリング
  def create_relation(attrs \\ %{}) do
      unless get_relation_ids(attrs["follower_id"], attrs["followee_id"]) do
        %Relation{follower_id: attrs["follower_id"], followee_id: attrs["followee_id"]}
        |> Relation.changeset(attrs)
        |> Repo.insert()
      else
        Logger.error("Bulk insertion error")
        {:error , "Bulk inserion error"}
      end
  end

  @doc """
  Updates a relation.

  ## Examples

      iex> update_relation(relation, %{field: new_value})
      {:ok, %Relation{}}

      iex> update_relation(relation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_relation(%Relation{} = relation, attrs) do
      relation
      |> Relation.changeset(attrs)
      |> Repo.update()
  end

  @doc """
  Deletes a relation.

  ## Examples

      iex> delete_relation(relation)
      {:ok, %Relation{}}

      iex> delete_relation(relation)
      {:error, %Ecto.Changeset{}}

  """
  def delete_relation(%Relation{} = relation) do
      Repo.delete(relation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking relation changes.

  ## Examples

      iex> change_relation(relation)
      %Ecto.Changeset{data: %Relation{}}

  """
  def change_relation(%Relation{} = relation, attrs \\ %{}) do
      Relation.changeset(relation, attrs)
  end
end
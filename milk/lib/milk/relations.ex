defmodule Milk.Relations do
  alias Milk.Accounts.Relation
  alias Milk.Accounts.User
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
  def get_relation_by_ids(follower_id, followee_id) do
    Relation
    |> where([r], r.follower_id == ^follower_id)
    |> where([r], r.followee_id == ^followee_id)
    |> Repo.one()
  end

  @doc """
  Get relation list of a specific user.
  """
  def get_following_list(user_id) do
    Relation
    |> where([r], r.follower_id == ^user_id)
    |> Repo.all()
    |> Enum.map(fn relation -> 
      User
      |> where([u], u.id == ^relation.followee_id)
      |> Repo.one()
    end)
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
  # TODO: Multiを使ったほうがいいかもしれない
  def create_relation(attrs \\ %{}) do
      unless get_relation_by_ids(attrs["follower_id"], attrs["followee_id"]) do
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
  Deletes a relation by follower id and followee id.
  """
  def delete_relation_by_ids(follower_id, followee_id) do
    get_relation_by_ids(follower_id, followee_id)
    |> IO.inspect()
    |> delete_relation()
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
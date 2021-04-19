defmodule Milk.Relations do
  alias Milk.{
    Repo,
    Accounts
  }
  alias Milk.Accounts.{
    Relation,
    User
  }
  alias Common.Tools

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
    if !is_nil(followee_id) and !is_nil(follower_id) do
      Relation
      |> where([r], r.follower_id == ^follower_id)
      |> where([r], r.followee_id == ^followee_id)
      |> Repo.one()
    else
      false
    end
  end

  @doc """
  Get relation list of a specific user.
  """
  def get_following_list(user_id) do
    user_id = Tools.to_integer_as_needed(user_id)

    Relation
    |> where([r], r.follower_id == ^user_id)
    |> Repo.all()
    |> Enum.map(fn relation ->
      Repo.one(
        from u in User,
        join: a in assoc(u, :auth),
        where: u.id == ^relation.followee_id,
        preload: [auth: a]
      )
    end)
  end


 # NOTE: ユーザーの詳細な情報は必要ないのでフォローしているIDリストを返す
  def get_following_id_list(user_id) do
    user_id = Tools.to_integer_as_needed(user_id)

    Relation
    |> where([r], r.follower_id == ^user_id)
    |> select([r], r.followee_id)
    |> Repo.all()
  end

  @doc """
  Get followers
  """
  def get_followers(user_id) do
    Relation
    |> where([r], r.followee_id == ^user_id)
    |> Repo.all()
    |> Enum.map(fn relation ->
      Accounts.get_user(relation.follower_id)
    end)
  end

  @doc """
  Get Followers
  """
  def get_followers_list(user_id) do
    user_id = Tools.to_integer_as_needed(user_id)

    Relation
    |> where([r], r.followee_id == ^user_id)
    |> Repo.all()
    |> Enum.map(fn relation ->
      Repo.one(
        from u in User,
        join: a in assoc(u, :auth),
        where: u.id == ^relation.follower_id,
        preload: [auth: a]
      )
    end)
  end

  def get_followers_id_list(user_id) do
    user_id = Tools.to_integer_as_needed(user_id)

    Relation
    |> where([r], r.followee_id == ^user_id)
    |> select([r], r.follower_id)
    |> Repo.all()
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
    follower_id = Tools.to_integer_as_needed(attrs["follower_id"])
    followee_id = Tools.to_integer_as_needed(attrs["followee_id"])

    get_relation_by_ids(follower_id, followee_id)
    |> unless do
      %Relation{follower_id: follower_id, followee_id: followee_id}
      |> Relation.changeset(attrs)
      |> Repo.insert()
    else
      Logger.error("Bulk insertion error")
      {:error, "Bulk inserion error"}
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
  def delete_relation_by_ids(attrs) do
    follower_id = if is_binary(attrs["follower_id"]) do
      String.to_integer(attrs["follower_id"])
    else
      attrs["follower_id"]
    end

    followee_id = if is_binary(attrs["followee_id"]) do
      String.to_integer(attrs["followee_id"])
    else
      attrs["followee_id"]
    end

    relation = get_relation_by_ids(follower_id, followee_id)
    if relation != nil do
      delete_relation(relation)
    else
      Logger.error("Bulk insertion error")
      {:error, "Bulk inserion error"}
    end
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

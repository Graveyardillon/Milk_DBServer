defmodule Milk.Relations do
  @moduledoc """
  Module of relations.
  """
  import Ecto.Query, warn: false

  require Logger

  alias Common.Tools

  alias Milk.{
    Repo,
    Accounts
  }

  alias Milk.Accounts.{
    BlockRelation,
    Relation,
    User
  }

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
  @spec get_relation_by_ids(integer(), integer()) :: Relation.t() | nil
  def get_relation_by_ids(follower_id, followee_id) when not is_nil(follower_id) and not is_nil(followee_id) do
    Relation
    |> where([r], r.follower_id == ^follower_id)
    |> where([r], r.followee_id == ^followee_id)
    |> Repo.one()
  end

  def get_relation_by_ids(_, _), do: nil

  @doc """
  Get relation list of a specific user.
  """
  def get_following_list(user_id) do
    user_id = Tools.to_integer_as_needed(user_id)

    Relation
    |> where([r], r.follower_id == ^user_id)
    |> Repo.all()
    |> Enum.map(fn relation ->
      User
      |> join(:inner, [u], a in assoc(u, :auth))
      |> where([u, a], u.id == ^relation.followee_id)
      |> preload([u, a], auth: a)
      |> Repo.one()
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
    |> Enum.map(&Accounts.get_user(&1.follower_id))
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
      User
      |> join(:inner, [u], a in assoc(u, :auth))
      |> where([u, a], u.id == ^relation.follower_id)
      |> preload([u, a], auth: a)
      |> Repo.one()
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
  def create_relation(attrs \\ %{}) do
    follower_id = Tools.to_integer_as_needed(attrs["follower_id"])
    followee_id = Tools.to_integer_as_needed(attrs["followee_id"])

    follower_id
    |> __MODULE__.get_relation_by_ids(followee_id)
    |> case do
      nil ->
        %Relation{follower_id: follower_id, followee_id: followee_id}
        |> Relation.changeset(attrs)
        |> Repo.insert()
      _ ->
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
  def delete_relation_by_ids(%{"follower_id" => follower_id, "followee_id" => followee_id}) do
    follower_id = Tools.to_integer_as_needed(follower_id)
    followee_id = Tools.to_integer_as_needed(followee_id)

    relation = __MODULE__.get_relation_by_ids(follower_id, followee_id)

    if !is_nil(relation) do
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

  @doc """
  Block a user.
  """
  def block(user_id, blocked_user_id) do
    %BlockRelation{block_user_id: user_id, blocked_user_id: blocked_user_id}
    |> BlockRelation.changeset(%{})
    |> Repo.insert()
  end

  @doc """
  Unblock a user.
  """
  def unblock(user_id, blocked_user_id) do
    BlockRelation
    |> where([br], br.block_user_id == ^user_id and br.blocked_user_id == ^blocked_user_id)
    |> Repo.one()
    |> Repo.delete()
  end

  @doc """
  Get blocked users.
  """
  def blocked_users(nil), do: []

  def blocked_users(user_id) do
    BlockRelation
    |> where([br], br.block_user_id == ^user_id)
    |> Repo.all()
  end
end

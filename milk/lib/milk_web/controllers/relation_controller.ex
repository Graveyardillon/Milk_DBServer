defmodule MilkWeb.RelationController do
  @moduledoc """
  Relation周り
  """
  use MilkWeb, :controller

  import Common.Sperm

  alias Common.Tools

  alias Milk.{
    Accounts,
    Relations
  }

  @doc """
  Follow a user.
  """
  def follow(conn, %{"relation" => params}) do
    case Relations.create_relation(params) do
      {:ok, _relation} -> json(conn, %{result: true})
      {:error, error}  -> json(conn, %{result: false, error: error})
    end
  end

  @doc """
  Unfollow a user.
  """
  def unfollow(conn, %{"relation" => params}) do
    case Relations.delete_relation_by_ids(params) do
      {:ok, _relation} -> json(conn, %{result: true})
      {:error, error}  -> json(conn, %{result: false, error: error})
    end
  end

  @doc """
  Get a following users list of a specific user.
  """
  def following_list(conn, %{"user_id" => user_id}) do
    users = Relations.get_following_list(user_id)
    render(conn, "user.json", users: users)
  end

  @doc """
  Get a list of following users' id.
  """
  def following_id_list(conn, %{"user_id" => user_id}) do
    users = Relations.get_following_id_list(user_id)
    render(conn, "id_list.json", list: users)
  end

  @doc """
  Get a list of followers.
  """
  def followers_list(conn, %{"user_id" => user_id}) do
    users = Relations.get_followers_list(user_id)
    render(conn, "users.json", users: users)
  end

  @doc """
  Get a list of followers' id.
  """
  def followers_id_list(conn, %{"user_id" => user_id}) do
    users = Relations.get_followers_id_list(user_id)
    render(conn, "id_list.json", list: users)
  end

  @doc """
  Get blocked users.
  """
  def blocked_users(conn, %{"user_id" => user_id}) do
    user_id = Tools.to_integer_as_needed(user_id)

    user_id
    |> Relations.blocked_users()
    |> Enum.map(&Accounts.get_user(&1.blocked_user_id))
    ~> users

    render(conn, "users.json", users: users)
  end

  @doc """
  Block a user.
  """
  def block_user(conn, %{"user_id" => user_id, "blocked_user_id" => blocked_user_id}) do
    user_id = Tools.to_integer_as_needed(user_id)
    blocked_user_id = Tools.to_integer_as_needed(blocked_user_id)

    user_id
    |> Relations.block(blocked_user_id)
    |> case do
      {:ok, _relation} -> json(conn, %{result: true})
      {:error, _error} -> json(conn, %{result: false})
    end
  end

  @doc """
  Unblock a user.
  """
  def unblock_user(conn, %{"user_id" => user_id, "blocked_user_id" => blocked_user_id}) do
    user_id = Tools.to_integer_as_needed(user_id)
    blocked_user_id = Tools.to_integer_as_needed(blocked_user_id)

    user_id
    |> Relations.unblock(blocked_user_id)
    |> case do
      {:ok, _relation} -> json(conn, %{result: true})
      {:error, _error} -> json(conn, %{result: false})
    end
  end
end

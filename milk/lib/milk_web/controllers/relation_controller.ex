defmodule MilkWeb.RelationController do
  use MilkWeb, :controller

  alias Milk.Relations

  @doc """
  Follow a user.
  """
  def create(conn, %{"relation" => params}) do
    case Relations.create_relation(params) do
      {:ok, _relation} ->
        json(conn, %{result: true})
      {:error, error} ->
        json(conn, %{result: false, error: error})
    end
  end

  @doc """
  Unfollow a user.
  """
  def delete(conn, %{"relation" => params}) do
    case Relations.delete_relation_by_ids(params) do
      {:ok, _relation} ->
        json(conn, %{result: true})
      {:error, error} -> 
        json(conn, %{result: false, error: error})
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
    render(conn, "user.json", users: users)
  end

  @doc """
  Get a list of followers' id.
  """
  def followers_id_list(conn, %{"user_id" => user_id}) do
    users = Relations.get_followers_id_list(user_id)
    render(conn, "id_list.json", list: users)
  end
end
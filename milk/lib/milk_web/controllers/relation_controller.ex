defmodule MilkWeb.RelationController do
  use MilkWeb, :controller

  alias Milk.Relations

  # follow
  def create(conn, %{"relation" => params}) do
    case Relations.create_relation(params) do
      {:ok, _relation} ->
        json(conn, %{result: true})
      {:error, error} ->
        json(conn, %{result: false, error: error})
    end
  end

  # unfollow
  def delete(conn, %{"relation" => params}) do
    case Relations.delete_relation_by_ids(params) do
    {:ok, _relation} ->
      json(conn, %{result: true})
    {:error, error} -> 
      json(conn, %{result: false, error: error})
    end
  end

  def following_list(conn, %{"user_id" => user_id}) do
    users = Relations.get_following_list(user_id)
    render(conn, "users.json", users: users)
  end
  def following_id_list(conn, %{"user_id" => user_id}) do
    users = Relations.get_following_id_list(user_id)
    render(conn, "id_list.json", list: users)
  end

end
defmodule MilkWeb.RelationController do
  use MilkWeb, :controller

  alias Milk.Relations
  alias Milk.Accounts.Relation

  # follow
  def create(conn, %{"relation" => params}) do
      {:ok, relation} = Relations.create_relation(params)

      render(conn, "show.json", relation: relation)
  end

  # unfollow
  def delete(conn, %{"relation" => params}) do
    {:ok, relation} = Relations.delete_relation_by_ids(params["follower_id"], params["followee_id"])

    render(conn, "show.json", relation: relation)
  end

  def following_list(conn, %{"user_id" => user_id}) do
    users = Relations.get_following_list(user_id)

    render(conn, "users.json", users: users)
  end
end
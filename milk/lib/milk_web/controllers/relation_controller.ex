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
    
  end

  def following_list(conn, %{"user_id" => user_id}) do
    relations = Relations.get_following_list(user_id)

    render(conn, "index.json", relations: relations)
  end
end
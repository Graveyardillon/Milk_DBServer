defmodule MilkWeb.RelationView do
  use MilkWeb, :view
  alias MilkWeb.RelationView
  alias Milk.Accounts.Relation

  def render("index.json", %{relations: relations}) do
    %{data: render_many(relations, RelationView, "relation.json")}
  end

  def render("show.json", %{relation: relation}) do
    %{data: render_one(relation, RelationView, "relation.json")}
  end

  def render("relation.json", %{relation: relation}) do
    IO.inspect(relation)
    %{
      id: relation.id,
      followee_id: relation.followee_id,
      follower_id: relation.follower_id
    }
  end
end
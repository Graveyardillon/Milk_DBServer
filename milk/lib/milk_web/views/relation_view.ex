defmodule MilkWeb.RelationView do
  use MilkWeb, :view
  alias MilkWeb.RelationView
  alias Milk.Accounts.Relation
  alias Milk.Accounts.User

  def render("index.json", %{relations: relations}) do
    %{data: render_many(relations, RelationView, "relation.json")}
  end

  def render("show.json", %{relation: relation}) do
    %{data: render_one(relation, RelationView, "relation.json")}
  end

  def render("relation.json", %{relation: relation}) do
    %{
      id: relation.id,
      followee_id: relation.followee_id,
      follower_id: relation.follower_id
    }
  end

  def render("users.json", %{users: users}) do
    m = 
      users
      |> IO.inspect(label: "before map")
      |> Enum.map(fn user -> 
        %{
          id: user.id,
          icon_path: user.icon_path,
          id_for_show: user.id_for_show,
          language: user.language,
          name: user.name,
          bio: user.bio,
          email: user.auth.email
        }
      end)
      |> IO.inspect(label: "after map")

    %{data: m}
  end
end
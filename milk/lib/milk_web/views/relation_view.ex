defmodule MilkWeb.RelationView do
  use MilkWeb, :view

  alias MilkWeb.{
    RelationView,
    UserView
  }

  def render("id_list.json", %{list: list}) do
    %{ids: list, result: true}
  end

  def render("users.json", %{users: users}) do
    %{
      data: render_many(users, UserView, "user.json"),
      result: true
    }
  end
end

defmodule MilkWeb.RelationController do
  use MilkWeb, :controller

  alias Milk.Relations
  alias Milk.Accounts.Relation

  def create(conn, %{"relation" => params}) do
      {:ok, relation} = Relations.create_relation(params)

      render(conn, "show.json", relation: relation)
  end
end
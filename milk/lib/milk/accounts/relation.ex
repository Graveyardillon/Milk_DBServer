defmodule Milk.Accounts.Relation do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Accounts.User

  schema "relations" do
    belongs_to :followee, User
    belongs_to :follower, User

    timestamps()
  end

  @doc false
  def changeset(relation, attrs) do
    relation
    |> cast(attrs, [])
    |> validate_required([:followee_id, :follower_id])
    |> foreign_key_constraint(:followee_id)
    |> foreign_key_constraint(:follower_id)
  end
end

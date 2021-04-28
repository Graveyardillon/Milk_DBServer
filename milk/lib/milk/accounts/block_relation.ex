defmodule Milk.Accounts.BlockRelation do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Accounts.User

  schema "block_relations" do
    belongs_to :blocked_user, User
    belongs_to :block_user, User

    timestamps()
  end

  @doc false
  def changeset(block_relation, attrs) do
    block_relation
    |> cast(attrs, [])
    |> validate_required([:blocked_user_id, :block_user_id])
    |> foreign_key_constraint(:blocked_user_id)
    |> foreign_key_constraint(:block_user_id)
  end
end

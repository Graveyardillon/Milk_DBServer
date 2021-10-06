defmodule Milk.Apple.User do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Accounts.User

  schema "apple_users" do
    field :apple_id, :string

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(apple_user, attrs) do
    apple_user
    |> cast(attrs, [:apple_id, :user_id])
    |> validate_required([:apple_id, :user_id])
  end
end

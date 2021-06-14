defmodule Milk.Accounts.Device do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Accounts.User

  schema "devices" do
    field :token, :string
    belongs_to :user, User

    timestamps()
  end

  def changeset(device, attrs) do
    device
    |> cast(attrs, [:token, :user_id])
    |> validate_required([:token])
    |> foreign_key_constraint(:user_id)
  end
end

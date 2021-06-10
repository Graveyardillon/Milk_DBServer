defmodule Milk.Accounts.Device do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Accounts.User

  schema "device" do
    field :token, :string
    belongs_to :user, User

    timestamps()
  end

  def changeset(device, attrs) do
    device
    |> cast(attrs, [:token])
    |> validate_required([:token])
  end
end

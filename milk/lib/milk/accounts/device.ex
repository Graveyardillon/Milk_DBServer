defmodule Milk.Accounts.Device do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Accounts.User

  @type t :: %__MODULE__{
    token: String.t(),
    user_id: integer(),
    # NOTE: timestamps
    create_time: any(),
    update_time: any()
  }

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

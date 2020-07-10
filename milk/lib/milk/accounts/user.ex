defmodule Milk.Accounts.User do
  use Milk.Schema
  import Ecto.Changeset
  alias Milk.Accounts.Auth

  schema "users" do
    field :icon_path, :string, default: nil
    field :logout_fl, :boolean, default: false
    field :language, :string
    field :name, :string
    field :notification_number, :integer, default: 0
    field :point, :integer, default: 0
    has_one :auth, Auth

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :icon_path, :point, :notification_number, :language, :logout_fl])
    # |> validate_required([:name, :icon_path, :point, :notification_number, :language])
    |> validate_required([:name])
  end
end

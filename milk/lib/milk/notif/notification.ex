defmodule Milk.Notif.Notification do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Accounts.User

  schema "notifications" do
    field :content, :string
    field :process_code, :integer
    field :data, :string
    field :is_checked, :boolean, default: false

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:content, :process_code, :data, :is_checked])
    |> validate_required([:content])
  end
end

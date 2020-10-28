defmodule Milk.Notif.Notification do
  use Milk.Schema
  import Ecto.Changeset
  alias Milk.Accounts.User

  schema "notification" do
    field :content, :string
    # field :user_id, :id
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:content])
    |> validate_required([:content])
  end
end

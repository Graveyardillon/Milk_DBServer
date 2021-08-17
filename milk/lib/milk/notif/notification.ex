defmodule Milk.Notif.Notification do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Accounts.User

  schema "notifications" do
    field :title, :string
    field :body_text, :string
    field :process_id, :string
    field :data, :string
    field :is_checked, :boolean, default: false
    field :icon_path, :string, default: nil

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:title, :body_text, :process_id, :data, :is_checked, :icon_path])
    |> validate_required([:title])
  end

  @doc false
  def update_changeset(notification, attrs) do
    notification
    |> cast(attrs, [:title, :body_text, :process_id, :data, :is_checked, :icon_path])
  end
end

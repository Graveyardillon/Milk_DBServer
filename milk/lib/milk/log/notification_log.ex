defmodule Milk.Log.NotificationLog do
  use Milk.Schema

  import Ecto.Changeset

  schema "notifications_log" do
    field :title, :string
    field :body_text, :string
    field :user_id, :integer
    field :data, :string
    field :process_id, :string

    timestamps()
  end

  @doc false
  def changeset(notification_log, attrs) do
    notification_log
    |> cast(attrs, [:user_id, :title, :body_text, :process_id, :data])
    |> validate_required([:user_id, :title])
  end
end

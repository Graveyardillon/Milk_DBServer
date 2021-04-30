defmodule Milk.Log.NotificationLog do
  use Milk.Schema
  import Ecto.Changeset

  schema "notifications_log" do
    field :content, :string
    field :user_id, :integer
    field :data, :string
    field :process_code, :integer

    timestamps()
  end

  @doc false
  def changeset(notification_log, attrs) do
    notification_log
    |> cast(attrs, [:user_id, :content, :process_code, :data])
    |> validate_required([:user_id, :content])
  end
end

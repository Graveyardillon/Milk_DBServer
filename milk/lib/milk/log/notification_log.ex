defmodule Milk.Log.NotificationLog do
  use Milk.Schema
  import Ecto.Changeset

  schema "notification_log" do
    field :content, :string
    field :user_id, :integer

    timestamps()
  end

  @doc false
  def changeset(notification_log, attrs) do
    notification_log
    |> cast(attrs, [:user_id, :content])
    |> validate_required([:user_id, :content])
  end
end

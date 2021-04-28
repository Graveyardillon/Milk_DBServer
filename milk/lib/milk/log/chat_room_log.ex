defmodule Milk.Log.ChatRoomLog do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.EctoDate

  @primary_key false
  schema "chat_room_log" do
    field :id, :integer, primary_key: true
    field :count, :integer
    field :last_chat, :string
    field :name, :string
    field :create_time, EctoDate
    field :update_time, EctoDate
    field :member_count, :integer
  end

  @doc false
  def changeset(chat_room_log, attrs) do
    chat_room_log
    |> cast(attrs, [:id, :name, :last_chat, :count, :create_time, :update_time])
    |> validate_required([:id, :name])
  end
end

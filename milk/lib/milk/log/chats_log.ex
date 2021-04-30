defmodule Milk.Log.ChatsLog do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.EctoDate

  schema "chat_log" do
    field :chat_room_id, :integer
    field :index, :integer
    field :user_id, :integer
    field :word, :string
    field :create_time, EctoDate
    field :update_time, EctoDate
  end

  @doc false
  def changeset(chats_log, attrs) do
    chats_log
    |> cast(attrs, [:chat_room_id, :word, :user_id, :index, :create_time, :update_time])
    |> validate_required([:chat_room_id, :word, :user_id, :index])
  end
end

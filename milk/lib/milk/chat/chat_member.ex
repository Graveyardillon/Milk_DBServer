defmodule Milk.Chat.ChatMember do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Accounts.User
  alias Milk.Chat.ChatRoom

  schema "chat_member" do
    field :authority, :integer, default: 0
    belongs_to :user, User
    belongs_to :chat_room, ChatRoom

    timestamps()
  end

  @doc false
  def changeset(chat_member, attrs) do
    chat_member
    |> cast(attrs, [:authority])
    |> unique_constraint([:user_id, :chat_room_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:chat_room_id)
  end
end

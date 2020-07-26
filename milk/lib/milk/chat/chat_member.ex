defmodule Milk.Chat.ChatMember do
  use Milk.Schema
  import Ecto.Changeset
  alias Milk.Accounts.User
  alias Milk.Chat.ChatRoom

  schema "chat_member" do
    field :authority, :integer
    # field :chat_room_id, :id
    # field :user_id, :id
    belongs_to :user, User
    belongs_to :chat_room, ChatRoom

    timestamps()
  end

  @doc false
  def changeset(chat_member, attrs) do
    chat_member
    |> cast(attrs, [:authority])
    |> validate_required([:authority])
    |> unique_constraint([:chat_room_id, :user_id])
  end
end

defmodule Milk.Chat.ChatRoom do
  use Milk.Schema
  import Ecto.Changeset
  alias Milk.Chat.Chats
  alias Milk.Chat.ChatMember
  alias Milk.Accounts.User
  alias Milk.EctoDate

  schema "chat_room" do
    field :count, :integer, default: 0
    field :last_chat, :string, default: nil
    field :name, :string
    field :member_count, :integer, default: 0
    has_many :chat, Chats
    many_to_many :user, User, join_through: "chat_member"
    has_many :chat_member, ChatMember
    
    timestamps()
  end

  @doc false
  def changeset(chat_room, attrs) do
    chat_room
    |> cast(attrs, [:name, :last_chat, :count, :member_count])
    |> validate_required([:name])
  end

  def changeset_update(chat_room, attrs) do
    chat_room
    |> cast(attrs, [:name, :last_chat, :count, :member_count])
    # |> validate_required([:name])
  end
end

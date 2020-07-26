defmodule Milk.Chat.Chats do
  use Milk.Schema
  import Ecto.Changeset
  alias Milk.Accounts.User
  alias Milk.Chat.ChatRoom

  schema "chat" do
    field :index, :integer
    field :word, :string
    # field :chat_room_id, :id
    # field :user_id, :id
    belongs_to :user, User
    belongs_to :chat_room, ChatRoom

    timestamps()
  end

  @doc false
  def changeset(chats, attrs) do
    chats
    |> cast(attrs, [:word])
    |> validate_required([:word])
    |> unique_constraint([:chat_room_id, :index])
  end
end

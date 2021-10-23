defmodule Milk.Chat.Chats do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Accounts.User
  alias Milk.Chat.ChatRoom

  @type t :: %__MODULE__{
          index: integer(),
          word: String.t(),
          user_id: integer(),
          chat_room_id: integer(),
          # NOTE: timestamps
          create_time: any(),
          update_time: any()
        }

  schema "chat" do
    field :index, :integer
    field :word, :string
    belongs_to :user, User
    belongs_to :chat_room, ChatRoom

    timestamps()
  end

  @doc false
  def changeset(chats, attrs) do
    chats
    |> cast(attrs, [:word])
    |> validate_required([:word])
    |> unique_constraint([:index, :chat_room_id])
  end
end

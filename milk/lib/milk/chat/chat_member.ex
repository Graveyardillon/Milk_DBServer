defmodule Milk.Chat.ChatMember do
  @moduledoc """
  Chat member
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Accounts.User
  alias Milk.Chat.ChatRoom

  @type t :: %__MODULE__{
          authority: integer(),
          user_id: integer(),
          chat_room_id: integer(),
          # NOTE: timestamps
          create_time: any(),
          update_time: any()
        }

  schema "chat_members" do
    field :authority, :integer, default: 0
    belongs_to :user, User
    belongs_to :chat_room, ChatRoom

    timestamps()
  end

  def changeset(attrs), do: __MODULE__.changeset(%__MODULE__{}, attrs)

  @doc false
  def changeset(chat_member, attrs) do
    chat_member
    |> cast(attrs, [:authority])
    |> unique_constraint([:user_id, :chat_room_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:chat_room_id)
  end
end

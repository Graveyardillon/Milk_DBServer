defmodule Milk.Accounts.User do
  use Milk.Schema
  import Ecto.Changeset
  alias Milk.Accounts.Auth
  alias Milk.Chat.Chats
  alias Milk.Chat.ChatMember
  alias Milk.Chat.ChatRoom
  alias Milk.Achievements.Achievement

  schema "users" do
    field :icon_path, :string, default: nil
    field :logout_fl, :boolean, default: false
    field :id_for_show, :integer
    field :language, :string
    field :name, :string
    field :bio, :string, default: nil
    field :notification_number, :integer, default: 0
    field :point, :integer, default: 0
    has_one :auth, Auth
    has_many :chat, Chats
    many_to_many :chat_room, ChatRoom, join_through: "chat_member"
    has_many :chat_member, ChatMember
    has_many :achievements, Achievement

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :bio, :icon_path, :point, :notification_number, :language, :logout_fl])
    # |> validate_required([:name, :icon_path, :point, :notification_number, :language])
    # |> validate_required([:name])
  end
end

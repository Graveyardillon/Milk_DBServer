defmodule Milk.Accounts.User do
  use Milk.Schema
  import Ecto.Changeset
  alias Milk.Accounts.Auth
  alias Milk.Chat.Chats
  alias Milk.Chat.ChatMember
  alias Milk.Chat.ChatRoom
  alias Milk.Lives.Live
  alias Milk.Tournaments.{Tournament, Entrant, Assistant}
  alias Milk.Notif.Notification

  schema "users" do
    field :icon_path, :string
    field :logout_fl, :boolean, default: false
    field :id_for_show, :integer
    field :language, :string, default: "japan"

    field :name, :string
    field :bio, :string, default: nil
    field :notification_number, :integer, default: 0
    field :point, :integer, default: 0
    field :win_count, :integer, default: 0

    has_one :auth, Auth
    has_many :chat, Chats
    many_to_many :chat_room, ChatRoom, join_through: "chat_member"
    has_many :chat_member, ChatMember
    has_many :tournament, Tournament, foreign_key: :master_id
    has_many :entrant, Entrant
    has_many :assistant, Assistant
    has_many :lives, Live, foreign_key: :streamer_id
    has_many :notif, Notification

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :icon_path, :point, :id_for_show, :notification_number, :language, :logout_fl])
    |> validate_required([:name])
    |> unique_constraint([:id_for_show, :name])
  end
end

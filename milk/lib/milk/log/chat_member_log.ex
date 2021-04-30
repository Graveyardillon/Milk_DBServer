defmodule Milk.Log.ChatMemberLog do
  use Milk.Schema
  alias Milk.EctoDate
  import Ecto.Changeset

  schema "chat_members_log" do
    field :authority, :integer
    field :chat_room_id, :integer
    field :user_id, :integer
    field :create_time, EctoDate
    field :update_time, EctoDate
  end

  @doc false
  def changeset(chat_member_log, attrs) do
    chat_member_log
    |> cast(attrs, [:chat_room_id, :user_id, :authority, :create_time, :update_time])
    |> validate_required([:chat_room_id, :user_id, :authority])
  end
end

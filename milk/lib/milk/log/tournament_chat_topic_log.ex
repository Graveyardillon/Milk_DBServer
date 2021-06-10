defmodule Milk.Log.TournamentChatTopicLog do
  use Milk.Schema

  import Ecto.Changeset

  schema "tournament_chat_topics_log" do
    field :topic_name, :string
    field :tournament_id, :integer
    field :tab_index, :integer
    field :chat_room_id, :integer
    field :is_deleted, :boolean, default: false

    timestamps()
  end

  @doc false
  def changeset(tournament_chat_topic_log, attrs) do
    tournament_chat_topic_log
    |> cast(attrs, [:topic_name, :tournament_id, :chat_room_id, :is_deleted, :tab_index])
    |> validate_required([:topic_name, :tournament_id, :chat_room_id, :is_deleted, :tab_index])
  end
end

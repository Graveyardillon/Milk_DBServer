defmodule Milk.Tournaments.TournamentChatTopic do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Tournament
  alias Milk.Chat.ChatRoom

  schema "tournament_chat_topics" do
    field :topic_name, :string
    field :tab_index, :integer
    belongs_to :tournament, Tournament
    belongs_to :chat_room, ChatRoom

    timestamps()
  end

  @doc false
  def changeset(tournament_chat_topic, attrs) do
    tournament_chat_topic
    |> cast(attrs, [:topic_name, :tab_index])
  end
end

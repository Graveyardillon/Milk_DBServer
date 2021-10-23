defmodule Milk.Tournaments.TournamentChatTopic do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Tournament
  alias Milk.Chat.ChatRoom

  @type t :: %__MODULE__{
          tab_index: integer(),
          topic_name: String.t(),
          tournament_id: integer(),
          chat_room_id: integer(),
          # NOTE: timestamps
          create_time: any(),
          update_time: any()
        }

  schema "tournament_chat_topics" do
    field :tab_index, :integer
    field :topic_name, :string

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

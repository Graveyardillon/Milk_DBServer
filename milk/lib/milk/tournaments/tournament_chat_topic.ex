defmodule Milk.Tournaments.TournamentChatTopic do
  use Milk.Schema
  import Ecto.Changeset
  alias Milk.Tournaments.Tournament

  schema "tournament_chat_topics" do
    field :topic_name, :string
    belongs_to :tournament, Tournament

    timestamps()
  end

  @doc false
  def changeset(tournament_chat_topic, attrs) do
    tournament_chat_topic
    |> cast(attrs, [:topic_name])
    #|> validate_required([:topic_name])
  end
end

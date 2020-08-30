defmodule Milk.Tournaments.TournamentChatTopic do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tournament_user_topics" do
    field :topic_name, :string

    timestamps()
  end

  @doc false
  def changeset(tournament_chat_topic, attrs) do
    tournament_chat_topic
    |> cast(attrs, [:topic_name])
    |> validate_required([:topic_name])
  end
end

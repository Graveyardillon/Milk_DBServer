defmodule Milk.Log.TournamentChatTopicLog do
  use Milk.Schema

  import Ecto.Changeset

  schema "tournament_chat_topic_log" do
    field :topic_name, :string

    timestamps()
  end

  @doc false
  def changeset(tournament_chat_topic_log, attrs) do
    tournament_chat_topic_log
    |> cast(attrs, [:topic_name])
    |> validate_required([:topic_name])
  end
end

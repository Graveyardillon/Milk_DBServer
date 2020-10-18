defmodule Milk.Tournaments.Tournament do
  use Milk.Schema
  import Ecto.Changeset
  alias Milk.Games.Game
  alias Milk.Accounts.User
  alias Milk.Tournaments.{Entrant, Assistant, TournamentChatTopic}

  schema "tournament" do
    field :capacity, :integer
    field :deadline, EctoDate
    field :description, :string
    field :event_date, EctoDate
    field :name, :string
    field :type, :integer
    field :url, :string
    field :thumbnail_path, :string
    field :password, :string
    field :live, :boolean
    field :join, :boolean
    field :count, :integer, default: 0
    field :game_name, :string
    field :is_started, :boolean, default: false
    # field :game_id, :id
    belongs_to :game, Game
    # field :master_id, :id
    belongs_to :master, User
    has_many :entrant, Entrant
    has_many :assistant, Assistant
    has_many :tournament_chat_topics, TournamentChatTopic

    timestamps()
  end

  @doc false
  def changeset(tournament, attrs) do
    tournament
    |> cast(attrs, [:name, :event_date, :capacity, :description, :deadline, :game_name, :thumbnail_path, :password, :live, :join, :type, :url, :count, :is_started])
    # |> validate_required([:name, :event_date, :capacity, :description, :deadline, :type, :url])
  end
end

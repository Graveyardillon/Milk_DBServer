defmodule Milk.Tournaments.Tournament do
  use Milk.Schema
  import Ecto.Changeset
  alias Milk.Games.Game
  alias Milk.Accounts.User
  alias Milk.Lives.Live
  alias Milk.Tournaments.{Entrant, Assistant, TournamentChatTopic}
  alias Milk.Platforms.Platform

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
    field :count, :integer, default: 0
    field :game_name, :string
    field :is_started, :boolean, default: false
    field :start_recruiting, EctoDate
    belongs_to :platform, Platform

    belongs_to :game, Game
    belongs_to :master, User
    has_many :lives, Live
    has_many :entrant, Entrant
    has_many :assistant, Assistant
    has_many :tournament_chat_topics, TournamentChatTopic

    timestamps()
  end

  @doc false
  def changeset(tournament, attrs) do
    tournament
    |> cast(attrs, [:name, :event_date, :capacity, :description, :deadline, :game_name, :thumbnail_path, :password, :type, :url, :count, :is_started, :start_recruiting])
    |> validate_required([:name, :event_date, :capacity, :deadline])
  end
end

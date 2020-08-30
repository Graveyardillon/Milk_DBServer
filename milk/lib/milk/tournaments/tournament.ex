defmodule Milk.Tournaments.Tournament do
  use Milk.Schema
  import Ecto.Changeset
  alias Milk.Games.Game
  alias Milk.Accounts.User
  alias Milk.Tournaments.{Entrant, Assistant}

  schema "tournament" do
    field :capacity, :integer
    field :deadline, EctoDate
    field :description, :string
    field :event_date, EctoDate
    field :name, :string
    field :type, :integer
    field :url, :string
    field :count, :integer, default: 0
    # field :game_id, :id
    belongs_to :game, Game
    # field :master_id, :id
    belongs_to :master, User
    has_many :entrant, Entrant
    has_many :assistant, Assistant

    timestamps()
  end

  @doc false
  def changeset(tournament, attrs) do
    tournament
    |> cast(attrs, [:name, :event_date, :capacity, :description, :deadline, :type, :url, :count])
    # |> validate_required([:name, :event_date, :capacity, :description, :deadline, :type, :url])
  end
end

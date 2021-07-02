defmodule Milk.Tournaments.Team do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Tournament
  alias Milk.Tournaments.TeamMember

  schema "teams" do
    field :name, :string
    field :size, :integer

    belongs_to :tournament, Tournament
    has_many :team_member, TeamMember

    timestamps()
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:name, :size, :tournament_id])
  end
end

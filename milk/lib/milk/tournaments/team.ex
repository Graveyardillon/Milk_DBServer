defmodule Milk.Tournaments.Team do
  @moduledoc """
  チームのスキーマ
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.{
    Tournament,
    TeamMember
  }
  alias Milk.Tournaments.Progress.TeamWinCount


  @type t :: %__MODULE__{
          confirmation_date: any(),
          icon_path: String.t() | nil,
          is_confirmed: boolean(),
          is_dummy: boolean(),
          name: String.t(),
          rank: integer(),
          size: integer() | nil,
          tournament_id: integer(),
          # NOTE: timestamps
          create_time: any(),
          update_time: any()
        }

  schema "teams" do
    field :confirmation_date, EctoDate
    field :icon_path, :string
    field :is_confirmed, :boolean, default: false
    field :is_dummy, :boolean, default: false
    field :name, :string
    field :rank, :integer, default: 0
    field :size, :integer

    belongs_to :tournament, Tournament
    has_many :team_member, TeamMember
    has_one :win_count, TeamWinCount

    timestamps()
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:confirmation_date, :name, :is_dummy, :size, :tournament_id, :icon_path, :is_confirmed, :rank])
    |> validate_required([:name, :tournament_id])
  end
end

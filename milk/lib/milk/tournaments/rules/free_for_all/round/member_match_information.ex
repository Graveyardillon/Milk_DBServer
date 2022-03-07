defmodule Milk.Tournaments.Rules.FreeForAll.Round.MemberMatchInformation do
  @moduledoc """
  match info(チームのメンバーたちのもの)
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Rules.FreeForAll.Round.{
    TeamMatchInformation,
    MemberPointMultiplier
  }
  alias Milk.Accounts.User

  @type t :: %__MODULE__{
    score: :integer | nil,
    team_match_information_id: :integer,
    # NOTE: timestamps
    create_time: any(),
    update_time: any()
  }

  schema "tournaments_rules_freeforall_round_membermatchinformation" do
    field :score, :integer

    belongs_to :team_match_information, TeamMatchInformation
    belongs_to :user, User

    has_many :point_multipliers, MemberPointMultiplier

    timestamps()
  end

  @doc false
  def changeset(info, attrs) do
    info
    |> cast(attrs, [:score, :team_match_information_id, :user_id])
    |> foreign_key_constraint(:team_match_information_id)
    |> foreign_key_constraint(:user_id)
  end
end

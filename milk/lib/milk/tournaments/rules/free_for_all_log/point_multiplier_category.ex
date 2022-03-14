defmodule Milk.Tournaments.Rules.FreeForAllLog.PointMultiplierCategory do
  @moduledoc """
  キルポイントのログとか
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Log.TournamentLog

  schema "tournaments_rules_freeforalllog_pointmultipliercategories" do
    field :name, :string
    field :multiplier, :float

    belongs_to :tournament, TournamentLog

    timestamps()
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :multiplier, :tournament_id])
    |> foreign_key_constraint(:tournament_id)
  end
end

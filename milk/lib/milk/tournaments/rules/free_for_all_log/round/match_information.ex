defmodule Milk.Tournaments.Rules.FreeForAllLog.Round.MatchInformation do
  @moduledoc """
  matchinfoのログ
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Rules.FreeForAllLog.Round.Information

  schema "tournaments_rules_freeforalllog_round_information" do
    field :score, :integer
    belongs_to :round, Information

    timestamps()
  end

  @doc false
  def changeset(info, attrs) do
    info
    |> cast(attrs, [:score, :round_id])
    |> foreign_key_constraint(:round_id)
  end
end

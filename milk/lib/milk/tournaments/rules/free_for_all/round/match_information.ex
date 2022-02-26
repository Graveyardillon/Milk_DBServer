defmodule Milk.Tournaments.Rules.FreeForAll.Round.MatchInformation do
  @moduledoc """
  match info （個人）
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Rules.FreeForAll.Round.Information

  schema "tournaments_rules_freeforall_round_matchinformation" do
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

defmodule Milk.Tournaments.Rules.FreeForAll.Round.TeamMatchInformation do
  @moduledoc """
  match info（チーム）
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Rules.FreeForAll.Round.Information

  schema "tournaments_rules_freeforall_round_teammatchinformation" do
    field :score, :integer

    belongs_to :round, Information

    timestamps()
  end

  @doc false
  def changeset(attrs, info) do
    info
    |> cast(attrs, [:score, :round_id])
    |> foreign_key_constraint(:round_id)
  end
end

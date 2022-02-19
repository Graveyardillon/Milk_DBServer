defmodule Milk.Tournaments.Rules.FreeForAll.Round.Table do
  @moduledoc """
  table
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Tournament

  schema "tournaments_rules_freeforall_round_table" do
    field :name, :string

    belongs_to :tournament, Tournament

    timestamps()
  end

  @doc false
  def changeset(attrs, table) do
    table
    |> cast(attrs, [:name, :tournament_id])
    |> foreign_key_constraint(:tournament_id)
  end
end

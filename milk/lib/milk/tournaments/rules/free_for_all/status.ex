defmodule Milk.Tournaments.Rules.FreeForAll.Status do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Tournament

  schema "tournaments_rules_freeforall_status" do
    field :current_round_index, :integer, default: 0

    belongs_to :tournament, Tournament

    timestamps()
  end

  @doc false
  def changeset(status, attrs) do
    status
    |> cast(attrs, [:current_round_index, :tournament_id])
    |> foreign_key_constraint(:tournament_id)
  end
end

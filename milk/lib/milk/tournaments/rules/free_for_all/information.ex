defmodule Milk.Tournaments.Rules.FreeForAll.Information do
  @moduledoc """
  情報
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Tournament

  schema "tournaments_rules_freeforall_information" do
    field :round_number, :integer
    field :match_number, :integer
    field :round_capacity, :integer

    belongs_to :tournament, Tournament

    timestamps()
  end

  @doc false
  def changeset(attrs, information) do
    information
    |> cast(attrs, [:round_number, :match_number, :round_capacity, :tournament_id])
    |> foreign_key_constraint(:tournament_id)
  end
end

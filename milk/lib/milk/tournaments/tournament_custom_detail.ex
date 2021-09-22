defmodule Milk.Tournaments.TournamentCustomDetail do
  @moduledoc """
  multiple_selection_type
  - VLCBAN
  """

  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Tournament

  schema "tournament_custom_details" do
    field :coin_head_field, :string
    field :coin_tail_field, :string
    field :map_rule, :string

    belongs_to :tournament, Tournament

    timestamps()
  end

  @doc false
  def changeset(tournament_custom_detail, attrs) do
    tournament_custom_detail
    |> cast(attrs, [
      :coin_head_field,
      :coin_tail_field,
      :map_rule,
      :tournament_id
    ])
    |> foreign_key_constraint(:tournament_id)
  end
end

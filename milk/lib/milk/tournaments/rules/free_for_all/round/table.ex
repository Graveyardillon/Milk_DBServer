defmodule Milk.Tournaments.Rules.FreeForAll.Round.Table do
  @moduledoc """
  FFAの対戦カードのこと
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Tournament

  @type t :: %__MODULE__{
    name: :string,
    round_index: :integer,
    tournament_id: :integer,
    # NOTE: timestamps
    create_time: any(),
    update_time: any()
  }

  schema "tournaments_rules_freeforall_round_table" do
    field :name, :string
    field :round_index, :integer

    belongs_to :tournament, Tournament

    timestamps()
  end

  @doc false
  def changeset(table, attrs) do
    table
    |> cast(attrs, [:name, :round_index, :tournament_id])
    |> foreign_key_constraint(:tournament_id)
  end
end

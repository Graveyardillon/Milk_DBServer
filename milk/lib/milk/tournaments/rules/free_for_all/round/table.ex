defmodule Milk.Tournaments.Rules.FreeForAll.Round.Table do
  @moduledoc """
  FFAの対戦カードのこと
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Tournament
  alias Milk.Tournaments.Rules.FreeForAll.Round.Information

  @type t :: %__MODULE__{
    name: :string,
    round_index: :integer,
    tournament_id: :integer,
    is_finished: :boolean,
    current_match_index: :integer,
    # NOTE: timestamps
    create_time: any(),
    update_time: any()
  }

  schema "tournaments_rules_freeforall_round_table" do
    field :name, :string
    field :round_index, :integer
    field :is_finished, :boolean
    field :current_match_index, :integer, default: 0

    belongs_to :tournament, Tournament

    has_many :information, Information

    timestamps()
  end

  @doc false
  def changeset(table, attrs) do
    table
    |> cast(attrs, [:name, :round_index, :tournament_id, :is_finished, :current_match_index])
    |> foreign_key_constraint(:tournament_id)
  end
end

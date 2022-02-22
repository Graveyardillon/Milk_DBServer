defmodule Milk.Tournaments.Rules.FreeForAll.Round.TeamMatchInformation do
  @moduledoc """
  match info（チーム）
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Rules.FreeForAll.Round.Information

  @type t :: %__MODULE__{
    score: :integer | nil,
    round_id: :integer,
    # NOTE: timestamps
    create_time: any(),
    update_time: any()
  }

  schema "tournaments_rules_freeforall_round_teammatchinformation" do
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

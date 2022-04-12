defmodule Milk.Tournaments.Rules.FreeForAll.PointMultiplierCategory do
  @moduledoc """
  キルポイントとかのやつ
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Tournament

  @type t :: %__MODULE__{
    name: :string,
    multiplier: :float,
    tournament_id: :integer,
    # NOTE: timestamps
    create_time: any(),
    update_time: any()
  }

  schema "tournaments_rules_freeforall_pointmultipliercategories" do
    field :name, :string
    field :multiplier, :float

    belongs_to :tournament, Tournament

    timestamps()
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :multiplier, :tournament_id])
    |> foreign_key_constraint(:tournament_id)
  end
end

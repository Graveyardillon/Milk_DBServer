defmodule Milk.Tournaments.Rules.FreeForAll.Information do
  @moduledoc """
  情報
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Tournament

  @type t :: %__MODULE__{
    enable_point_multiplier: :boolean,
    round_number: :integer,
    match_number: :integer,
    round_capacity: :integer,
    tournament_id: :integer,
    is_truncation_enabled: :boolean,
    # NOTE: timestamps
    create_time: any(),
    update_time: any()
  }

  schema "tournaments_rules_freeforall_information" do
    field :round_number, :integer
    field :match_number, :integer
    field :round_capacity, :integer
    field :enable_point_multiplier, :boolean, default: false
    field :is_truncation_enabled, :boolean, default: false

    belongs_to :tournament, Tournament

    timestamps()
  end

  @doc false
  def changeset(information, attrs) do
    information
    |> cast(attrs, [:round_number, :match_number, :round_capacity, :enable_point_multiplier, :tournament_id, :is_truncation_enabled])
    |> foreign_key_constraint(:tournament_id)
  end
end

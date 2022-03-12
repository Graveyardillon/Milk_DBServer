defmodule Milk.Tournaments.Rules.FreeForAllLog.Information do
  @moduledoc """
  情報ログ
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Log.TournamentLog

  schema "tournaments_rules_freeforalllog_information" do
    field :round_number, :integer
    field :match_number, :integer
    field :round_capacity, :integer
    field :enable_point_multiplier, :boolean, default: false
    field :is_truncation_enabled, :boolean, default: false

    belongs_to :tournament, TournamentLog

    timestamps()
  end

  @doc false
  def changeset(information, attrs) do
    information
    |> cast(attrs, [:round_number, :match_number, :round_capacity, :enable_point_multiplier, :tournament_id, :is_truncation_enabled])
    |> foreign_key_constraint(:tournament_id)
  end
end

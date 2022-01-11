defmodule Milk.Tournaments.RoundRobinLog do
  @moduledoc """
  Round Robinルールで使用するログデータ
  """
  use Milk.Schema

  import Ecto.Changeset

  schema "round_robin_log" do
    field :tournament_id, :integer
    field :match_list_str, :string
    field :rematch_index, :integer

    timestamps()
  end

  @doc false
  def changeset(round_robin_log, attrs) do
    round_robin_log
    |> cast(attrs, [:tournament_id, :match_list_str, :rematch_index])
    |> validate_required([:tournament_id, :match_list_str, :rematch_index])
  end
end

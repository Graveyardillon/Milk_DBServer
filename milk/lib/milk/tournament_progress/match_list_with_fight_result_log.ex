defmodule Milk.TournamentProgress.MatchListWithFightResultLog do
  use Milk.Schema

  import Ecto.Changeset

  schema "match_list_with_fight_result_log" do
    field :tournament_id, :integer
    field :match_list_with_fight_result_str, :string

    timestamps()
  end

  @doc false
  def changeset(match_list_with_fight_result_log, attrs) do
    match_list_with_fight_result_log
    |> cast(attrs, [:tournament_id, :match_list_with_fight_result_str])
    |> validate_required([:tournament_id, :match_list_with_fight_result_str])
  end
end

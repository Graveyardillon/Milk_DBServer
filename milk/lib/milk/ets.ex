defmodule Milk.Ets do
  def create_match_list_table() do
    :ets.new(:match_list, [:set, :public, :named_table])
  end

  def insert_match_list(tournament_id, match_list) do
    :ets.insert_new(:match_list, {tournament_id, match_list})
  end

  def get_match_list(tournament_id) do
    :ets.lookup(:match_list, tournament_id)
  end
end
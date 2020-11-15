defmodule Milk.Ets do
  def create_match_list_table() do
    :ets.new(:match_list, [:set, :public, :named_table])
  end

  def create_match_pending_list_table() do
    :ets.new(:match_pending_list, [:set, :public, :named_table])
  end

  def insert_match_list(tournament_id, match_list) do
    :ets.insert_new(:match_list, {tournament_id, match_list})
  end

  def insert_match_pending_list_table(tournament_id, user_id) do
    :ets.insert_new(:match_pending_list, {tournament_id, user_id})
  end

  def get_match_list(tournament_id) do
    :ets.lookup(:match_list, tournament_id)
  end

  def get_match_pending_list(user_id) do
    :ets.lookup(:match_pending_list, user_id)
  end
end
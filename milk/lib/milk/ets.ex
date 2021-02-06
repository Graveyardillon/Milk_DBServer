defmodule Milk.Ets do
  def create_match_list_table() do
    :ets.new(:match_list, [:set, :public, :named_table])
  end

  def create_match_list_with_fight_result_table() do
    :ets.new(:match_list_with_fight_result, [:set, :public, :named_table])
  end

  def create_match_pending_list_table() do
    :ets.new(:match_pending_list, [:set, :public, :named_table])
  end

  def create_fight_result_table() do
    :ets.new(:fight_result, [:set, :public, :named_table])
  end

  defp conn() do
    host = Application.get_env(:milk, :redix_host)
      |> IO.inspect()
    port = Application.get_env(:milk, :redix_port)
      |> IO.inspect()
    {:ok, conn} = Redix.start_link(host: host, port: port)
    conn
  end

  def insert_match_list(match_list, tournament_id) do
    #:ets.insert_new(:match_list, {tournament_id, match_list})
    conn = conn()
    bin = inspect(match_list)

    with {:ok, _} <- Redix.command(conn, ["SET", tournament_id, bin])|>IO.inspect() do
      true
    else
      _ -> false
    end
  end

  def insert_match_list_with_fight_result(match_list, tournament_id) do
    :ets.insert_new(:match_list_with_fight_result, {tournament_id, match_list})
  end

  def insert_match_pending_list_table({user_id, tournament_id}) do
    :ets.insert_new(:match_pending_list, {{user_id, tournament_id}})
  end

  def insert_fight_result_table({user_id, tournament_id}, is_win) do
    :ets.insert_new(:fight_result, {{user_id, tournament_id}, is_win})
  end

  def get_match_list(tournament_id) do
    :ets.lookup(:match_list, tournament_id)
  end

  def get_match_list_with_fight_result(tournament_id) do
    :ets.lookup(:match_list_with_fight_result, tournament_id)
  end

  def get_match_pending_list({user_id, tournament_id}) do
    :ets.lookup(:match_pending_list, {user_id, tournament_id})
  end

  def get_fight_result({user_id, tournament_id}) do
    :ets.lookup(:fight_result, {user_id, tournament_id})
  end

  def delete_match_list(tournament_id) do
    :ets.delete(:match_list, tournament_id)
  end

  def delete_match_list_with_fight_result(tournament_id) do
    :ets.delete(:match_list_with_fight_result, tournament_id)
  end

  def delete_match_pending_list({user_id, tournament_id}) do
    :ets.delete(:match_pending_list, {user_id, tournament_id})
  end

  def delete_fight_result({user_id, tournament_id}) do
    :ets.delete(:fight_result, {user_id, tournament_id})
  end
end

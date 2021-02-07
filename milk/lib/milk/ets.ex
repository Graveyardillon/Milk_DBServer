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
    port = Application.get_env(:milk, :redix_port)
    with {:ok, conn} <- Redix.start_link(host: host, port: port) do
      conn
    else
      error -> error
    end
  end

  def insert_match_list(match_list, tournament_id) do
    conn = conn()
    bin = inspect(match_list)

    with {:ok, _} <- Redix.command(conn, ["SELECT", 1]),
    {:ok, _} <- Redix.command(conn, ["SET", tournament_id, bin]) do
      true
    else
      _ -> false
    end
  end

  def insert_match_list_with_fight_result(match_list, tournament_id) do
    conn = conn()
    bin = inspect(match_list)

    with {:ok, _} <- Redix.command(conn, ["SELECT", 2]),
    {:ok, _} <- Redix.command(conn, ["SET", tournament_id, bin]) do
      true
    else
      _ -> false
    end
  end

  def insert_match_pending_list_table({user_id, tournament_id}) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 3]),
    {:ok, _} <- Redix.command(conn, ["HSET", tournament_id, user_id, true]) do
      true
    else
      _ -> false
    end
  end

  def insert_fight_result_table({user_id, tournament_id}, is_win) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 4]),
    {:ok, _} <- Redix.command(conn, ["HSET", tournament_id, user_id, is_win]) do
      true
    else
      _ -> false
    end
  end

  def get_match_list(tournament_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 1]),
    {:ok, value} <- Redix.command(conn, ["GET", tournament_id]) do
      {match_list, _} = Code.eval_string(value)
      [{tournament_id, match_list}]
    else
      _ -> nil
    end
  end

  def get_match_list_with_fight_result(tournament_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 2]),
    {:ok, value} <- Redix.command(conn, ["GET", tournament_id]) do
      {match_list, _} = Code.eval_string(value)
      [{tournament_id, match_list}]
    else
      _ -> nil
    end
  end

  def get_match_pending_list({user_id, tournament_id}) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 3]),
    {:ok, value} <- Redix.command(conn, ["HGET", tournament_id, user_id]) do
      {b, _} = Code.eval_string(value)
      if b, do: [{{user_id, tournament_id}}], else: nil
    else
      _ -> nil
    end
  end

  def get_fight_result({user_id, tournament_id}) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 4]),
    {:ok, value} <- Redix.command(conn, ["HGET", tournament_id, user_id]) do
      {is_win, _} = Code.eval_string(value)
      [{{user_id, tournament_id}, is_win}]
    else
      _ -> nil
    end
  end

  def delete_match_list(tournament_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 1]),
    {:ok, _} <- Redix.command(conn, ["DEL", tournament_id]) do
      true
    else
      _ -> false
    end
  end

  def delete_match_list_with_fight_result(tournament_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 2]),
    {:ok, _} <- Redix.command(conn, ["DEL", tournament_id]) do
      true
    else
      _ -> false
    end
  end

  def delete_match_pending_list({user_id, tournament_id}) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 3]),
    {:ok, _} <- Redix.command(conn, ["HDEL", tournament_id, user_id]) do
      true
    else
      _ -> false
    end
  end

  def delete_fight_result({user_id, tournament_id}) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 3]),
    {:ok, _} <- Redix.command(conn, ["HDEL", tournament_id, user_id]) do
      true
    else
      _ -> false
    end
  end
end

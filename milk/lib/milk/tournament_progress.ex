defmodule Milk.TournamentProgress do
  @moduledoc """
  1. match_list
  2. match_list_with_fight_result
  3. match_pending_list
  4. fight_result
  5. duplicate_users
  6. absence_process
  """
  alias Milk.Tournaments

  require Logger

  defp conn() do
    host = Application.get_env(:milk, :redix_host)
    port = Application.get_env(:milk, :redix_port)
    with {:ok, conn} <- Redix.start_link(host: host, port: port) do
      conn
    else
      error -> error
    end
  end

  @doc """
  Delete redis data all.
  This is mostly used in development environment.
  """
  def flushall() do
    conn = conn()
    Redix.command(conn, ["FLUSHALL"])
    Logger.info("Redis has been flushed all")
  end

  @moduledoc """
  1. match_list
  Manages match list which is used in tournament.
  The data form is like `[[2, 1], 3]`.
  """
  def insert_match_list(match_list, tournament_id) do
    conn = conn()
    bin = inspect(match_list)

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
    {:ok, _} <- Redix.command(conn, ["SELECT", 1]),
    {:ok, _} <- Redix.command(conn, ["SET", tournament_id, bin]),
    {:ok, _} <- Redix.command(conn, ["EXEC"]) do
      true
    else
      {:error, %Redix.Error{message: message}} ->
        Logger.error(message)
        false
      _ ->
        Logger.error("Could not insert match list")
        false
    end
  end

  def get_match_list(tournament_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 1]),
    {:ok, value} <- Redix.command(conn, ["GET", tournament_id]) do
      if value do
        {match_list, _} = Code.eval_string(value)
        [{tournament_id, match_list}]
      else
        []
      end
    else
      _ -> []
    end
  end

  def delete_match_list(tournament_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
    {:ok, _} <- Redix.command(conn, ["SELECT", 1]),
    {:ok, _} <- Redix.command(conn, ["DEL", tournament_id]),
    {:ok, _} <- Redix.command(conn, ["EXEC"]) do
      true
    else
      _ -> false
    end
  end

  @doc """
  FIXME: 排他ロックするための処理を記述する
  排他処理用のテーブルは0番テーブルとする。
  """
  def renew_match_list(loser, tournament_id) do
    # 更新は正常にできている
    conn = conn()
    {:ok, _} = Redix.command(conn, ["SELECT", 1])
    {:ok, value} = Redix.command(conn, ["SETNX", -tournament_id, 1])

    if value == 1 do
      {:ok, _} = Redix.command(conn, ["EXPIRE", -tournament_id, 20])
      {:ok, _} = Redix.command(conn, ["SELECT", 1])
      {:ok, value} = Redix.command(conn, ["GET", tournament_id])
      {match_list, _} = Code.eval_string(value)
      match_list = Tournamex.delete_loser(match_list, loser)
      bin = inspect(match_list)
      {:ok, _} = Redix.command(conn, ["DEL", tournament_id])
      {:ok, _} = Redix.command(conn, ["SET", tournament_id, bin])
      {:ok, _} = Redix.command(conn, ["DEL", -tournament_id])
      true
    else
      false
    end
  end

  @moduledoc """
  2. match_list_with_fight_result
  Manages match list with fight result.
  The purpose of this list is drawing brackets.
  Data form is like
  [
    %{"user_id" => 3, "is_loser" => false, "name" => "testname", "win_count" => 0},
    [
      %{"user_id" => 1, "is_loser" => false, "name" => "testname", "win_count" => 0},
      %{"user_id" => 2, "is_loser" => false, "name" => "testname", "win_count" => 0}
    ]
  ]
  """

  @doc """
  insert match list with fight result.
  """
  def insert_match_list_with_fight_result(match_list, tournament_id) do
    conn = conn()
    bin = inspect(match_list)

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
    {:ok, _} <- Redix.command(conn, ["SELECT", 2]),
    {:ok, _} <- Redix.command(conn, ["SET", tournament_id, bin]),
    {:ok, _} <- Redix.command(conn, ["EXEC"]) do
      true
    else
      _ -> false
    end
  end

  def get_match_list_with_fight_result(tournament_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 2]),
    {:ok, value} <- Redix.command(conn, ["GET", tournament_id]) do
      {match_list, _} = Code.eval_string(value)
      [{tournament_id, match_list}]
    else
      _ ->
        []
    end
  end

  def delete_match_list_with_fight_result(tournament_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
    {:ok, _} <- Redix.command(conn, ["SELECT", 2]),
    {:ok, _} <- Redix.command(conn, ["DEL", tournament_id]),
    {:ok, _} <- Redix.command(conn, ["EXEC"]) do
      true
    else
      _error ->
        false
    end
  end

  def renew_match_list_with_fight_result(loser, tournament_id) do
    conn = conn()

    {:ok, _} = Redix.command(conn, ["SELECT", 2])
    {:ok, value} = Redix.command(conn, ["SETNX", -tournament_id, 2])

    if value == 1 do
      {:ok, _} = Redix.command(conn, ["EXPIRE", -tournament_id, 20])
      {:ok, _} = Redix.command(conn, ["SELECT", 2])
      {:ok, value} = Redix.command(conn, ["GET", tournament_id])
      {match_list, _} = Code.eval_string(value)
      match_list = Tournamex.renew_match_list_with_loser(match_list, loser)
      bin = inspect(match_list)
      {:ok, _} = Redix.command(conn, ["DEL", tournament_id])
      {:ok, _} = Redix.command(conn, ["SET", tournament_id, bin])
      {:ok, _} = Redix.command(conn, ["DEL", -tournament_id])
      true
    else
      false
    end
  end

  @moduledoc """
  3. match_pending_list
  Manages match pending list.
  The list contains user_id of a user who pressed start_match and
  the fight is not finished.
  """
  def insert_match_pending_list_table({user_id, tournament_id}) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
    {:ok, _} <- Redix.command(conn, ["SELECT", 3]),
    {:ok, _} <- Redix.command(conn, ["HSET", tournament_id, user_id, true]),
    {:ok, _} <- Redix.command(conn, ["EXEC"]) do
      true
    else
      _ -> false
    end
  end

  def get_match_pending_list({user_id, tournament_id}) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 3]),
    {:ok, value} <- Redix.command(conn, ["HGET", tournament_id, user_id]) do
      {b, _} = Code.eval_string(value)
      if b, do: [{{user_id, tournament_id}}], else: []
    else
      _ -> []
    end
  end

  def delete_match_pending_list({user_id, tournament_id}) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
    {:ok, _} <- Redix.command(conn, ["SELECT", 3]),
    {:ok, _} <- Redix.command(conn, ["HDEL", tournament_id, user_id]),
    {:ok, _} <- Redix.command(conn, ["EXEC"]) do
      true
    else
      _error ->
        false
    end
  end

  @moduledoc """
  4. match_pending_list
  Manages fight result.
  """
  def insert_fight_result_table({user_id, tournament_id}, is_win) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
    {:ok, _} <- Redix.command(conn, ["SELECT", 4]),
    {:ok, _} <- Redix.command(conn, ["HSET", tournament_id, user_id, is_win]),
    {:ok, _} <- Redix.command(conn, ["EXEC"]) do
      true
    else
      _ -> false
    end
  end

  def get_fight_result({user_id, tournament_id}) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 4]),
    {:ok, value} <- Redix.command(conn, ["HGET", tournament_id, user_id]) do
      if value do
        {is_win, _} = Code.eval_string(value)
        [{{user_id, tournament_id}, is_win}]
      else
        []
      end
    else
      _ -> []
    end
  end

  def delete_fight_result({user_id, tournament_id}) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
    {:ok, _} <- Redix.command(conn, ["SELECT", 4]),
    {:ok, _} <- Redix.command(conn, ["HDEL", tournament_id, user_id]),
    {:ok, _} <- Redix.command(conn, ["EXEC"]) do
      true
    else
      _ -> false
    end
  end

  @doc """
  5. duplicate_users
  Manages duplicate users whose claims are same as their opponent.
  """
  def add_duplicate_user_id(tournament_id, user_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
    {:ok, _} <- Redix.command(conn, ["SELECT", 5]),
    {:ok, _} <- Redix.command(conn, ["SADD", tournament_id, user_id]),
    {:ok, _} <- Redix.command(conn, ["EXEC"]) do
      true
    else
      _ -> false
    end
  end

  def get_duplicate_users(tournament_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 5]),
    {:ok, value} <- Redix.command(conn, ["SMEMBERS", tournament_id]) do
      Enum.map(value, fn v ->
        String.to_integer(v)
      end)
    else
      _v -> []
    end
  end

  def delete_duplicate_user(tournament_id, user_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 5]),
    {:ok, n} <- Redix.command(conn, ["SCARD", tournament_id]),
    {:ok, got_user_id_list} <- Redix.command(conn, ["SPOP", tournament_id, n]) do
      Enum.each(got_user_id_list, fn got_user_id ->
        unless got_user_id == to_string(user_id) do
          Redix.command(conn, ["SADD", tournament_id, got_user_id])
        end
      end)
      true
    else
      _ -> false
    end
  end

  def delete_duplicate_users_all(tournament_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 5]),
    {:ok, n} <- Redix.command(conn, ["SCARD", tournament_id]),
    {:ok, _} <- Redix.command(conn, ["SPOP", tournament_id, n]) do
      true
    else
      _ -> false
    end
  end

  @moduledoc """
  6. absence_process
  The process manages users who did not press 'start' button for 5 mins.
  """
  def set_time_limit_on_entrant(user_id, tournament_id) do
    get_lost(user_id, tournament_id)
  end

  def set_time_limit_on_all_entrants(match_list, tournament_id) do
    Logger.info("Set time limit on all entrants")
    match_list
    |> List.flatten()
    |> Enum.each(fn user_id ->
      get_lost(user_id, tournament_id)
    end)
  end

  defp get_lost(user_id, tournament_id) do
    # 敗北のプロセスを生成
    pid_str =
      Task.async(fn ->
        IO.inspect(user_id)
        IO.inspect("get_lost is called")
        5
        |> Kernel.*(60)
        |> Kernel.*(1000)
        |> Process.sleep()

        IO.inspect("#{user_id} loses")

        Tournaments.delete_loser_process(tournament_id, [user_id])
      end)
      |> case do
        %Task{pid: pid} ->
          IO.inspect(pid)
          IO.inspect("losing process is generated")
          pid
          |> :erlang.pid_to_list()
          |> inspect()
      end

    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 6]),
    {:ok, _} <- Redix.command(conn, ["HSET", tournament_id, user_id, pid_str]) do
      true
    else
      _ -> false
    end
  end

  # 敗北処理をキャンセル
  def cancel_lose(tournament_id, user_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 6]),
    {:ok, value} <- Redix.command(conn, ["HGET", tournament_id, user_id]) do
      if value do
        {_, _, pid_str} = value
        pid = Code.eval_string(pid_str)
      else
        nil
      end
    else
      _ -> nil
    end
  end
end

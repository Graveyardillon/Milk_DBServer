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

    with {:ok, _} <- Redix.command(conn, ["SELECT", 1]),
    {:ok, _} <- Redix.command(conn, ["SET", tournament_id, bin]) do
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

    with {:ok, _} <- Redix.command(conn, ["SELECT", 1]),
    {:ok, _} <- Redix.command(conn, ["DEL", tournament_id]) do
      true
    else
      _ -> false
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

    with {:ok, _} <- Redix.command(conn, ["SELECT", 2]),
    {:ok, _} <- Redix.command(conn, ["SET", tournament_id, bin]) do
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
      e ->
        IO.inspect(e, label: :e)
        []
    end
  end

  def delete_match_list_with_fight_result(tournament_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 2]),
    {:ok, _} <- Redix.command(conn, ["DEL", tournament_id]) do
      true
    else
      _error ->
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

    with {:ok, _} <- Redix.command(conn, ["SELECT", 3]),
    {:ok, _} <- Redix.command(conn, ["HSET", tournament_id, user_id, true]) do
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

    with {:ok, _} <- Redix.command(conn, ["SELECT", 3]),
    {:ok, _} <- Redix.command(conn, ["HDEL", tournament_id, user_id]) do
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

    with {:ok, _} <- Redix.command(conn, ["SELECT", 4]),
    {:ok, _} <- Redix.command(conn, ["HSET", tournament_id, user_id, is_win]) do
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

    with {:ok, _} <- Redix.command(conn, ["SELECT", 4]),
    {:ok, _} <- Redix.command(conn, ["HDEL", tournament_id, user_id]) do
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

  end

  def set_time_limit_on_all_entrants(match_list, tournament_id) do
    Milk.Enum.creep(match_list, fn v -> get_lost(v, tournament_id) end)
  end

  defp get_lost(user_id, tournament_id) do
    IO.inspect(user_id, label: :user_id)
    IO.inspect(tournament_id, label: :tournament_id)

    # 敗北のプロセスを生成
    pid_str =
      Task.async(fn ->
        5
        |> Kernel.*(60)
        |> Kernel.*(1000)
        |> Process.sleep()

        # 敗北処理
        IO.inspect(tournament_id, label: :after_sleep)
        #Logger.info("will get lost" <> to_string(user_id))
        Tournaments.delete_loser_process(tournament_id, [user_id])
      end)
      |> case do
        %Task{pid: pid} ->
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

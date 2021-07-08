defmodule Milk.TournamentProgress do
  @moduledoc """
  1. match_list
  2. match_list_with_fight_result
  3. match_pending_list
  4. fight_result
  5. duplicate_users
  6. absence_process
  """
  import Ecto.Query, warn: false
  import Common.Sperm
  import Common.Comment

  alias Milk.{
    Accounts,
    Repo,
    Tournaments
  }

  alias Milk.TournamentProgress.{
    BestOfXTournamentMatchLog,
    MatchListWithFightResultLog,
    SingleTournamentMatchLog
  }

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

  # 1. match_list
  # Manages match list which is used in tournament.
  # The data form is like `[[2, 1], 3]`.

  def insert_match_list(match_list, tournament_id) do
    conn = conn()
    bin = inspect(match_list, charlists: false)

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
        match_list
      else
        []
      end
    else
      {:error, %Redix.Error{message: message}} ->
        Logger.error(message)
        []

      _ ->
        []
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
      {:error, %Redix.Error{message: message}} ->
        Logger.error(message)
        []

      _ ->
        false
    end
  end

  @doc """

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
      bin = inspect(match_list, charlists: false)
      {:ok, _} = Redix.command(conn, ["DEL", tournament_id])
      {:ok, _} = Redix.command(conn, ["SET", tournament_id, bin])
      {:ok, _} = Redix.command(conn, ["DEL", -tournament_id])
      true
    else
      false
    end
  end

  # 2. match_list_with_fight_result
  # Manages match list with fight result.
  # The purpose of this list is drawing brackets.
  # Data form is like
  # [
  #   %{"user_id" => 3, "is_loser" => false, "name" => "testname", "win_count" => 0},
  #   [
  #     %{"user_id" => 1, "is_loser" => false, "name" => "testname", "win_count" => 0},
  #     %{"user_id" => 2, "is_loser" => false, "name" => "testname", "win_count" => 0}
  #   ]
  # ]

  @doc """
  insert match list with fight result.
  """
  def insert_match_list_with_fight_result(match_list, tournament_id) do
    conn = conn()
    bin = inspect(match_list, charlists: false)

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
         {:ok, _} <- Redix.command(conn, ["SELECT", 2]),
         {:ok, _} <- Redix.command(conn, ["SET", tournament_id, bin]),
         {:ok, _} <- Redix.command(conn, ["EXEC"]) do
      true
    else
      {:error, %Redix.Error{message: message}} ->
        Logger.error(message)
        []

      _ ->
        false
    end
  end

  def get_match_list_with_fight_result(tournament_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 2]),
         {:ok, value} <- Redix.command(conn, ["GET", tournament_id]) do
      if value do
        {match_list, _} = Code.eval_string(value)
        match_list
      else
        []
      end
    else
      {:error, %Redix.Error{message: message}} ->
        Logger.error(message)
        []

      _ ->
        []
    end
  end

  def get_match_list_with_fight_result_including_log(tournament_id) do
    tournament_id
    |> get_match_list_with_fight_result()
    |> case do
      [] ->
        tournament_id
        |> get_match_list_with_fight_result_log()
        |> Map.get(:match_list_with_fight_result_str)
        |> Code.eval_string()
        |> elem(0)

      match_list ->
        match_list
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
      {:error, %Redix.Error{message: message}} ->
        Logger.error(message)
        false

      _ ->
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
      bin = inspect(match_list, charlists: false)
      {:ok, _} = Redix.command(conn, ["DEL", tournament_id])
      {:ok, _} = Redix.command(conn, ["SET", tournament_id, bin])
      {:ok, _} = Redix.command(conn, ["DEL", -tournament_id])
      true
    else
      false
    end
  end

  # 3. match_pending_list
  # Manages match pending list.
  # The list contains user_id of a user who pressed start_match and
  # the fight is not finished.

  def insert_match_pending_list_table(user_id, tournament_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
         {:ok, _} <- Redix.command(conn, ["SELECT", 3]),
         {:ok, _} <- Redix.command(conn, ["HSET", tournament_id, user_id, true]),
         {:ok, _} <- Redix.command(conn, ["EXEC"]) do
      true
    else
      {:error, %Redix.Error{message: message}} ->
        Logger.error(message)
        false

      _ ->
        false
    end
  end

  def get_match_pending_list(user_id, tournament_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 3]),
         {:ok, value} <- Redix.command(conn, ["HGET", tournament_id, user_id]) do
      {b, _} = Code.eval_string(value)
      if b, do: [{{user_id, tournament_id}}], else: []
    else
      {:error, %Redix.Error{message: message}} ->
        Logger.error(message)
        []

      _ ->
        []
    end
  end

  def get_match_pending_list_of_tournament(tournament_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 3]),
         {:ok, value} <- Redix.command(conn, ["HKEYS", tournament_id]) do
      value
    else
      {:error, %Redix.Error{message: message}} ->
        Logger.error(message)
        []

      _ ->
        []
    end
  end

  def delete_match_pending_list(user_id, tournament_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
         {:ok, _} <- Redix.command(conn, ["SELECT", 3]),
         {:ok, _} <- Redix.command(conn, ["HDEL", tournament_id, user_id]),
         {:ok, _} <- Redix.command(conn, ["EXEC"]) do
      true
    else
      {:error, %Redix.Error{message: message}} ->
        Logger.error(message)
        false

      _ ->
        false
    end
  end

  def delete_match_pending_list_of_tournament(tournament_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 3]),
         {:ok, value} <- Redix.command(conn, ["HKEYS", tournament_id]) do
      Enum.each(value, fn key ->
        key = String.to_integer(key)
        Redix.command(conn, ["HDEL", tournament_id, key])
      end)

      true
    else
      {:error, %Redix.Error{message: message}} ->
        Logger.error(message)
        false

      _ ->
        false
    end
  end

  # 4. match_pending_list
  # Manages fight result.
  # FIXME: 引数のタプルをやめたい

  def insert_fight_result_table(user_id, tournament_id, is_win) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
         {:ok, _} <- Redix.command(conn, ["SELECT", 4]),
         {:ok, _} <- Redix.command(conn, ["HSET", tournament_id, user_id, is_win]),
         {:ok, _} <- Redix.command(conn, ["EXEC"]) do
      true
    else
      {:error, %Redix.Error{message: message}} ->
        Logger.error(message)
        false

      _ ->
        false
    end
  end

  def get_fight_result(user_id, tournament_id) do
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
      {:error, %Redix.Error{message: message}} ->
        Logger.error(message)
        []

      _ ->
        []
    end
  end

  def delete_fight_result(user_id, tournament_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
         {:ok, _} <- Redix.command(conn, ["SELECT", 4]),
         {:ok, _} <- Redix.command(conn, ["HDEL", tournament_id, user_id]),
         {:ok, _} <- Redix.command(conn, ["EXEC"]) do
      true
    else
      {:error, %Redix.Error{message: message}} ->
        Logger.error(message)
        false

      _ ->
        false
    end
  end

  def delete_fight_result_of_tournament(tournament_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 4]),
         {:ok, value} <- Redix.command(conn, ["HKEYS", tournament_id]) do
      Enum.each(value, fn key ->
        key = String.to_integer(key)
        Redix.command(conn, ["HDEL", tournament_id, key])
      end)

      true
    else
      {:error, %Redix.Error{message: message}} ->
        Logger.error(message)
        false

      _ ->
        false
    end
  end

  # 5. duplicate_users
  # Manages duplicate users whose claims are same as their opponent.

  def add_duplicate_user_id(tournament_id, user_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
         {:ok, _} <- Redix.command(conn, ["SELECT", 5]),
         {:ok, _} <- Redix.command(conn, ["SADD", tournament_id, user_id]),
         {:ok, _} <- Redix.command(conn, ["EXEC"]) do
      true
    else
      {:error, %Redix.Error{message: message}} ->
        Logger.error(message)
        false

      _ ->
        false
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
      {:error, %Redix.Error{message: message}} ->
        Logger.error(message)
        []

      _ ->
        []
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
      {:error, %Redix.Error{message: message}} ->
        Logger.error(message)
        false

      _ ->
        false
    end
  end

  def delete_duplicate_users_all(tournament_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 5]),
         {:ok, n} <- Redix.command(conn, ["SCARD", tournament_id]),
         {:ok, _} <- Redix.command(conn, ["SPOP", tournament_id, n]) do
      true
    else
      {:error, %Redix.Error{message: message}} ->
        Logger.error(message)
        false

      _ ->
        false
    end
  end

  # 6. absence_process
  # The process manages users who did not press 'start' button for 5 mins.

  @doc """
  Set a time limit on entrant.
  When the time limit becomes due, the user gets lost.
  """
  def set_time_limit_on_entrant(user_id, tournament_id) do
    get_lost(user_id, tournament_id)
  end

  @doc """
  Set a time limit on entrants of a tournament.
  """
  def set_time_limit_on_all_entrants(match_list, tournament_id) do
    Logger.info("Set time limit on all entrants")

    match_list
    |> List.flatten()
    |> Enum.each(fn user_id ->
      get_lost(user_id, tournament_id)
    end)
  end

  # TODO: 検証が不十分なためコメントアウトしておいた
  defp get_lost(user_id, tournament_id) do
    # Generate a process which makes a user lost
    # pid_str =
    #   Task.start(fn ->
    #     5
    #     |> Kernel.*(60)
    #     |> Kernel.*(1000)
    #     |> Process.sleep()

    #     Tournaments.delete_loser_process(tournament_id, [user_id])
    #   end)
    #   |> case do
    #     {:ok, pid} ->
    #       pid
    #       |> :erlang.pid_to_list()
    #       |> inspect()
    #   end

    # conn = conn()

    # with {:ok, _} <- Redix.command(conn, ["SELECT", 6]),
    # {:ok, _} <- Redix.command(conn, ["HSET", tournament_id, user_id, pid_str]) do
    #   true
    # else
    #   _ -> false
    # end
  end

  @doc """

  """
  def get_lost_pid(user_id, tournament_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 6]),
         {:ok, value} <- Redix.command(conn, ["HGET", tournament_id, user_id]) do
      if value do
        value
        |> Code.eval_string()
        |> elem(0)
        |> :erlang.list_to_pid()
      else
        nil
      end
    else
      _ -> nil
    end
  end

  @doc """
  Cancel a process which makes a user lost.
  TODO: delete処理
  """
  def cancel_lose(tournament_id, user_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 6]),
         {:ok, value} <- Redix.command(conn, ["HGET", tournament_id, user_id]) do
      if value do
        pid =
          value
          |> Code.eval_string()
          |> elem(0)
          |> :erlang.list_to_pid()
          |> Process.exit(:kill)

        {:ok, pid}
      else
        {:error, nil}
      end
    else
      error -> {:error, error}
    end
    |> case do
      {:ok, _} ->
        with {:ok, _} <- Redix.command(conn, ["SELECT", 6]),
             {:ok, _value} <- Redix.command(conn, ["HDEL", tournament_id, user_id]) do
          true
        else
          _ -> false
        end

      {:error, _error} ->
        false
    end
  end

  def delete_lose_processes(tournament_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 6]),
         {:ok, value} <- Redix.command(conn, ["HKEYS", tournament_id]) do
      Enum.each(value, fn key ->
        key = String.to_integer(key)
        Redix.command(conn, ["HDEL", tournament_id, key])
      end)

      true
    else
      {:error, %Redix.Error{message: message}} ->
        Logger.error(message)
        false

      _ ->
        false
    end
  end

  # 7. scores
  # Instead of fight result, we use scores for players fight result management.

  def insert_score(tournament_id, user_id, score) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
         {:ok, _} <- Redix.command(conn, ["SELECT", 7]),
         {:ok, _} <- Redix.command(conn, ["HSET", tournament_id, user_id, score]),
         {:ok, _} <- Redix.command(conn, ["EXEC"]) do
      true
    else
      {:error, %Redix.Error{message: message}} ->
        Logger.error(message)
        false

      _ ->
        false
    end
  end

  def get_score(tournament_id, user_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 7]),
         {:ok, value} <- Redix.command(conn, ["HGET", tournament_id, user_id]) do
      if value do
        {score, _} = Code.eval_string(value)
        score
      else
        []
      end
    else
      {:error, %Redix.Error{message: message}} ->
        Logger.error(message)
        []

      _ ->
        []
    end
  end

  def delete_score(tournament_id, user_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
         {:ok, _} <- Redix.command(conn, ["SELECT", 7]),
         {:ok, _} <- Redix.command(conn, ["HDEL", tournament_id, user_id]),
         {:ok, _} <- Redix.command(conn, ["EXEC"]) do
      true
    else
      {:error, %Redix.Error{message: message}} ->
        Logger.error(message)
        false

      _ ->
        false
    end
  end

  # Single tournament match log.
  # Single tournament match log stores a progress information.

  # We have no idea of presenting this information in iOS,
  # but just storing them in a database.

  @doc """
  Get single tournament match log.
  """
  def get_single_tournament_match_log(id), do: Repo.get(SingleTournamentMatchLog, id)

  @doc """
  Get a tournament match log by tournament_id and user_id
  """
  def get_single_tournament_match_logs(tournament_id, user_id) do
    SingleTournamentMatchLog
    |> where([s], s.tournament_id == ^tournament_id)
    |> where([s], s.winner_id == ^user_id or s.loser_id == ^user_id)
    |> Repo.all()
  end

  @doc """
  Create single tournament match log.
  """
  def create_single_tournament_match_log(attrs \\ %{}) do
    %SingleTournamentMatchLog{}
    |> SingleTournamentMatchLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Get best of x tournament match log.
  """
  def get_best_of_x_tournament_match_logs(tournament_id) do
    BestOfXTournamentMatchLog
    |> where([b], b.tournament_id == ^tournament_id)
    |> Repo.all()
  end

  def get_best_of_x_tournament_match_logs_by_winner(tournament_id, user_id) do
    BestOfXTournamentMatchLog
    |> where([b], b.tournament_id == ^tournament_id)
    |> where([b], b.winner_id == ^user_id)
    |> Repo.all()
  end

  def get_best_of_x_tournament_match_logs_by_loser(tournament_id, user_id) do
    BestOfXTournamentMatchLog
    |> where([b], b.tournament_id == ^tournament_id)
    |> where([b], b.loser_id == ^user_id)
    |> Repo.all()
  end

  def create_best_of_x_tournament_match_log(attrs \\ %{}) do
    %BestOfXTournamentMatchLog{}
    |> BestOfXTournamentMatchLog.changeset(attrs)
    |> Repo.insert()
  end

  comment """
  match list with fight result log.
  """

  def get_match_list_with_fight_result_log(tournament_id) do
    MatchListWithFightResultLog
    |> where([l], l.tournament_id == ^tournament_id)
    |> Repo.one()
  end

  def create_match_list_with_fight_result_log(attrs \\ %{}) do
    %MatchListWithFightResultLog{}
    |> MatchListWithFightResultLog.changeset(attrs)
    |> Repo.insert()
  end

  comment """
  大会スタート時に使用する関数群
  """

  def start_single_elimination(master_id, tournament) do
    Tournaments.start(master_id, tournament.id)
    make_single_elimination_matches(tournament.id)
  end

  def start_best_of_format(master_id, tournament) do
    Tournaments.start(master_id, tournament.id)
    {:ok, match_list} = make_best_of_format_matches(tournament)
    {:ok, match_list, nil}
  end

  defp make_single_elimination_matches(tournament_id) do
    with {:ok, match_list} <-
           Tournaments.get_entrants(tournament_id)
           |> Enum.map(fn x -> x.user_id end)
           |> Tournaments.generate_matchlist() do
      count =
        Tournaments.get_tournament(tournament_id)
        |> Map.get(:count)

      match_list
      |> Tournaments.initialize_rank(count, tournament_id)

      match_list
      |> insert_match_list(tournament_id)

      list_with_fight_result =
        match_list
        |> match_list_with_fight_result()

      lis =
        list_with_fight_result
        |> Tournamex.match_list_to_list()

      complete_list =
        Enum.reduce(lis, list_with_fight_result, fn x, acc ->
          user = Accounts.get_user(x["user_id"])

          acc
          |> Tournaments.put_value_on_brackets(user.id, %{"name" => user.name})
          |> Tournaments.put_value_on_brackets(user.id, %{"win_count" => 0})
          |> Tournaments.put_value_on_brackets(user.id, %{"icon_path" => user.icon_path})
        end)
        |> insert_match_list_with_fight_result(tournament_id)

      {:ok, match_list, complete_list}
    else
      {:error, error} ->
        {:error, error, nil}
    end
  end

  defp match_list_with_fight_result(match_list) do
    Tournaments.initialize_match_list_with_fight_result(match_list)
  end

  defp make_best_of_format_matches(tournament) do
    {:ok, match_list} =
      tournament.id
      |> Tournaments.get_entrants()
      |> Enum.map(fn x -> x.user_id end)
      |> Tournaments.generate_matchlist()

    count = tournament.count
    Tournaments.initialize_rank(match_list, count, tournament.id)
    insert_match_list(match_list, tournament.id)

    match_list_with_fight_result = match_list_with_fight_result(match_list)

    match_list_with_fight_result
    |> List.flatten()
    |> Enum.reduce(match_list_with_fight_result, fn x, acc ->
      user = Accounts.get_user(x["user_id"])

      acc
      |> Tournaments.put_value_on_brackets(user.id, %{"name" => user.name})
      |> Tournaments.put_value_on_brackets(user.id, %{"win_count" => 0})
      |> Tournaments.put_value_on_brackets(user.id, %{"icon_path" => user.icon_path})
      |> Tournaments.put_value_on_brackets(user.id, %{"round" => 0})
    end)
    |> insert_match_list_with_fight_result(tournament.id)

    {:ok, match_list}
  end
end

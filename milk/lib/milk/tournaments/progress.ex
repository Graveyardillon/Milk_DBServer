defmodule Milk.Tournaments.Progress do
  @moduledoc """
  1. match_list
  2. match_list_with_fight_result
  3. match_pending_list
  4. fight_result
  5. duplicate_users
  6. absence_process
  7. scores
  8. ban order
  9. a/d state
  """
  import Ecto.Query, warn: false
  import Common.{
    Comment,
    Sperm
  }

  alias Milk.{
    Accounts,
    Repo,
    Tournaments
  }

  alias Milk.Tournaments.{
    Team,
    Tournament
  }
  alias Milk.Tournaments.Progress.{
    BestOfXTournamentMatchLog,
    MatchListWithFightResultLog,
    SingleTournamentMatchLog
  }

  require Logger

  @type match_list :: [any()] | integer()
  @type match_list_with_fight_result :: [any()] | map()

  defp conn() do
    host = Application.get_env(:milk, :redix_host)
    port = Application.get_env(:milk, :redix_port)

    [host: host, port: port]
    |> Redix.start_link()
    |> case do
      {:ok, conn} -> conn
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

  @spec get_match_list(integer()) :: match_list()
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
  @spec insert_match_list_with_fight_result(match_list(), integer()) :: boolean()
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

  @is_waiting_for_start "IsWaitingForStart"
  @is_waiting_for_coin_flip "IsWaitingForCoinFlip"
  # @should_choose_map "ShouldChooseMap"

  def insert_match_pending_list_table(user_id, tournament_id) do
    # 大会タイプで分岐入れよう
    tournament = Tournaments.get_tournament(tournament_id)
    _pending_state = get_match_pending_list(user_id, tournament_id)

    should_flip_coin? = tournament.enabled_coin_toss

    cond do
      should_flip_coin? ->
        @is_waiting_for_coin_flip

      true ->
        @is_waiting_for_start
    end
    ~> key

    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
         {:ok, _} <- Redix.command(conn, ["SELECT", 3]),
         {:ok, _} <- Redix.command(conn, ["HSET", tournament_id, user_id, key]),
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
      unless is_nil(value) do
        [{{user_id, tournament_id}, value}]
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

  @spec get_fight_result(integer(), integer()) :: boolean() | nil
  def get_fight_result(user_id, tournament_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 4]),
         {:ok, value} <- Redix.command(conn, ["HGET", tournament_id, user_id]) do
      if value do
        {is_win, _} = Code.eval_string(value)
        is_win
      else
        nil
      end
    else
      {:error, %Redix.Error{message: message}} ->
        Logger.error(message)
        nil

      _ -> nil
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

  @spec get_score(integer(), integer()) :: integer() | [any()]
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

  # TODO: 大会がスタートしたタイミングで参加者（チーム）分のオートマトンを初期化する
  # TODO: どのオートマトンを使うのかはルールに応じて変更する
  # TODO: それからはアクションが起こるたびにオートマトンに対して入力を追加する

  # NOTE: 大会ルールに基づいてオートマトンを生成する関数
  @spec define_state_machine(Tournament.t()) :: any()
  def define_state_machine(_tournament) do
  end

  # 8. ban order
  # 0 -> 1 -> 2 -> 3 -> 4
  def init_ban_order(tournament_id, id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
         {:ok, _} <- Redix.command(conn, ["SELECT", 8]),
         {:ok, _} <- Redix.command(conn, ["HSET", tournament_id, id, 0]),
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

  def insert_ban_order(tournament_id, id, order) when is_integer(order) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
         {:ok, _} <- Redix.command(conn, ["SELECT", 8]),
         {:ok, _} <- Redix.command(conn, ["HSET", tournament_id, id, order]),
         {:ok, _} <- Redix.command(conn, ["EXEC"]) do
    else
      {:error, %Redix.Error{message: message}} ->
        Logger.error(message)
        false

      _ ->
        false
    end
  end

  def get_ban_order(tournament_id, id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 8]),
         {:ok, value} <- Redix.command(conn, ["HGET", tournament_id, id]) do
      unless is_nil(value) do
        value
        |> Integer.parse()
        |> elem(0)
      end
    else
      {:error, %Redix.Error{message: message}} ->
        Logger.error(message)
        []

      _ ->
        []
    end
  end

  def delete_ban_order(tournament_id, id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
         {:ok, _} <- Redix.command(conn, ["SELECT", 8]),
         {:ok, _} <- Redix.command(conn, ["HDEL", tournament_id, id]),
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

  # 9. a/d state
  # attacker side or defender side.
  def insert_is_attacker_side(id, tournament_id, is_attacker_side)
      when is_boolean(is_attacker_side) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
         {:ok, _} <- Redix.command(conn, ["SELECT", 9]),
         {:ok, _} <- Redix.command(conn, ["HSET", tournament_id, id, is_attacker_side]),
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

  def is_attacker_side?(id, tournament_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 9]),
         {:ok, value} <- Redix.command(conn, ["HGET", tournament_id, id]) do
      unless is_nil(value) do
        value
        |> Code.eval_string()
        |> elem(0)
      else
        nil
      end
    else
      {:error, %Redix.Error{message: message}} ->
        Logger.error(message)
        nil

      _ ->
        nil
    end
  end

  def delete_is_attacker_side(id, tournament_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
         {:ok, _} <- Redix.command(conn, ["SELECT", 9]),
         {:ok, _} <- Redix.command(conn, ["HDEL", tournament_id, id]),
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

  comment("""
  match list with fight result log.
  """)

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

  comment("""
  個人大会スタート時に使用する関数群
  """)

  @spec start_single_elimination(integer(), Tournament.t()) :: {:ok, match_list(), match_list_with_fight_result()}
  def start_single_elimination(master_id, tournament) do
    Tournaments.start(tournament.id, master_id)
    make_single_elimination_matches(tournament.id)
  end

  @spec start_best_of_format(integer(), Tournament.t()) :: {:ok, match_list(), nil}
  def start_best_of_format(master_id, tournament) do
    Tournaments.start(tournament.id, master_id)
    {:ok, match_list} = make_best_of_format_matches(tournament)
    {:ok, match_list, nil}
  end

  defp make_single_elimination_matches(tournament_id) do
    tournament_id
    |> Tournaments.get_entrants()
    |> Enum.map(fn x -> x.user_id end)
    |> Tournaments.generate_matchlist()
    ~> {:ok, match_list}

    tournament = Tournaments.get_tournament(tournament_id)
    count = tournament.count

    Tournaments.initialize_rank(match_list, count, tournament_id)
    insert_match_list(match_list, tournament_id)
    list_with_fight_result = match_list_with_fight_result(match_list)

    list_with_fight_result
    |> List.flatten()
    |> Enum.reduce(list_with_fight_result, fn x, acc ->
      user = Accounts.get_user(x["user_id"])

      acc
      |> Tournaments.put_value_on_brackets(user.id, %{"name" => user.name})
      |> Tournaments.put_value_on_brackets(user.id, %{"win_count" => 0})
      |> Tournaments.put_value_on_brackets(user.id, %{"icon_path" => user.icon_path})
    end)
    |> insert_match_list_with_fight_result(tournament_id)

    {:ok, match_list, list_with_fight_result}
  end

  defp match_list_with_fight_result(match_list) do
    Tournaments.initialize_match_list_with_fight_result(match_list)
  end

  defp make_best_of_format_matches(tournament) do
    tournament.id
    |> Tournaments.get_entrants()
    |> Enum.map(fn entrant -> entrant.user_id end)
    |> Tournaments.generate_matchlist()
    ~> {:ok, match_list}
    |> elem(1)
    |> insert_match_list(tournament.id)

    count = tournament.count
    Tournaments.initialize_rank(match_list, count, tournament.id)

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

  comment("""
  チーム大会スタートに関する関数群
  """)

  @spec start_team_best_of_format(integer(), Tournament.t()) :: {:ok, match_list(), match_list_with_fight_result()} | {:error, String.t(), nil}
  def start_team_best_of_format(master_id, tournament) do
    tournament.id
    |> Tournaments.start_team_tournament(master_id)
    |> case do
      {:ok, _} -> generate_team_best_of_format_matches(tournament)
      {:error, error} -> {:error, error, nil}
    end
  end

  defp generate_team_best_of_format_matches(tournament) do
    tournament.id
    |> Tournaments.get_confirmed_teams()
    ~> teams
    |> Enum.map(fn team -> team.id end)
    |> Tournaments.generate_matchlist()
    ~> {:ok, match_list}
    |> elem(1)
    |> insert_match_list(tournament.id)

    count = length(teams)
    Tournaments.initialize_team_rank(match_list, count)

    match_list
    |> Tournaments.initialize_match_list_of_team_with_fight_result()
    ~> match_list_with_fight_result

    match_list_with_fight_result
    |> List.flatten()
    |> Enum.reduce(match_list_with_fight_result, fn x, acc ->
      team = Tournaments.get_team(x["team_id"])

      # leaderの情報を記載したいため、そのデータを入れる
      team.id
      |> Tournaments.get_leader()
      |> Map.get(:user)
      ~> user

      acc
      |> Tournaments.put_value_on_brackets(team.id, %{"name" => user.name})
      |> Tournaments.put_value_on_brackets(team.id, %{"win_count" => 0})
      |> Tournaments.put_value_on_brackets(team.id, %{"icon_path" => user.icon_path})
      |> Tournaments.put_value_on_brackets(team.id, %{"round" => 0})
    end)
    |> insert_match_list_with_fight_result(tournament.id)

    {:ok, match_list, match_list_with_fight_result}
  end

  @doc """
  Get necessary id for tournament progress.
  """
  @spec get_necessary_id(integer(), integer()) :: integer() | nil
  def get_necessary_id(tournament_id, user_id) do
    tournament_id
    |> Tournaments.get_tournament()
    |> do_get_necessary_id(user_id)
  end

  defp do_get_necessary_id(nil, _), do: nil
  defp do_get_necessary_id(%Tournament{id: id, is_team: true}, user_id) do
    id
    |> Tournaments.get_team_by_tournament_id_and_user_id(user_id)
    |> get_team_id()
  end
  defp do_get_necessary_id(_, user_id), do: user_id

  defp get_team_id(%Team{id: id}), do: id
  defp get_team_id(_), do: nil
end

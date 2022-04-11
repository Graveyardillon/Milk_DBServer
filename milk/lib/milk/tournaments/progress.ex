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
  import Common.Sperm

  alias Common.Tools
  alias Milk.{
    Accounts,
    Log,
    Repo,
    Tournaments
  }

  alias Milk.Log.{
    TeamLog,
    TournamentLog
  }

  alias Milk.Tournaments.{
    Rules,
    Team,
    Tournament
  }
  alias Milk.Tournaments.Progress.{
    BestOfXTournamentMatchLog,
    MatchListWithFightResultLog,
    RoundRobinLog,
    SingleTournamentMatchLog,
    TeamWinCount
  }
  alias Milk.Tournaments.Rules.{
    FlipBanRoundRobin,
    FreeForAll
  }

  alias Tournamex.RoundRobin

  require Logger

  @type match_list :: [any()] | integer() | map()
  @type match_list_with_fight_result :: [any()] | map()

  defp conn() do
    host = Application.get_env(:milk, :redix_host)
    port = Application.get_env(:milk, :redix_port)

    case Redix.start_link(host: host, port: port) do
      {:ok, conn} -> conn
      error       -> error
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

  @spec insert_match_list(any(), integer()) :: {:ok, nil} | {:error, String.t()}
  def insert_match_list(match_list, tournament_id) do
    conn = conn()
    bin = inspect(match_list, charlists: false)

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
         {:ok, _} <- Redix.command(conn, ["SELECT", 1]),
         {:ok, _} <- Redix.command(conn, ["SET", tournament_id, bin]),
         {:ok, _} <- Redix.command(conn, ["EXEC"]) do
      {:ok, nil}
    else
      {:error, %Redix.Error{message: message}} -> {:error, message}
      _                                        -> {:error, "Could not insert match list"}
    end
  end

  @spec get_match_list(integer()) :: match_list() | nil
  def get_match_list(tournament_id) do
    conn = conn()

    with {:ok, _}                            <- Redix.command(conn, ["SELECT", 1]),
         {:ok, value} when not is_nil(value) <- Redix.command(conn, ["GET", tournament_id]) do
      value
      |> Code.eval_string()
      |> elem(0)
    else
      _ -> nil
    end
  end

  @spec delete_match_list(integer()) :: {:ok, nil} | {:error, String.t()}
  def delete_match_list(tournament_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
         {:ok, _} <- Redix.command(conn, ["SELECT", 1]),
         {:ok, _} <- Redix.command(conn, ["DEL", tournament_id]),
         {:ok, _} <- Redix.command(conn, ["EXEC"]) do
      {:ok, nil}
    else
      {:error, %Redix.Error{message: message}} -> {:error, message}
      _                                        -> {:error, "Could not delete match list"}
    end
  end

  @doc """
  Renew match list
  """
  @spec renew_match_list(integer() | [integer()], integer()) :: {:ok, nil} | {:error, String.t()}
  def renew_match_list(loser, tournament_id) do
    conn = conn()

    with {:ok, _}                                    <- Redix.command(conn, ["SELECT", 1]),
         {:ok, value} when value == 1                <- Redix.command(conn, ["SETNX", -tournament_id, 1]),
         {:ok, _}                                    <-  Redix.command(conn, ["EXPIRE", -tournament_id, 20]),
         {:ok, _}                                    <- Redix.command(conn, ["SELECT", 1]),
         {:ok, value}                                <- Redix.command(conn, ["GET", tournament_id]),
         {match_list, _} when not is_nil(match_list) <- Code.eval_string(value),
         match_list                                  <- Tournaments.delete_loser(match_list, loser),
         bin                                         <- inspect(match_list, charlists: false),
         {:ok, _}                                    <- Redix.command(conn, ["DEL", tournament_id]),
         {:ok, _}                                    <- Redix.command(conn, ["SET", tournament_id, bin]),
         {:ok, _}                                    <- Redix.command(conn, ["DEL", -tournament_id]) do
      {:ok, nil}
    else
      {:error, %Redix.Error{message: message}} -> {:error, message}
      _                                        -> {:error, "Could not renew match list"}
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
  @spec insert_match_list_with_fight_result(match_list(), integer()) :: {:ok, nil} | {:error, String.t()}
  def insert_match_list_with_fight_result(match_list, tournament_id) do
    conn = conn()
    bin = inspect(match_list, charlists: false)

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
         {:ok, _} <- Redix.command(conn, ["SELECT", 2]),
         {:ok, _} <- Redix.command(conn, ["SET", tournament_id, bin]),
         {:ok, _} <- Redix.command(conn, ["EXEC"]) do
      {:ok, nil}
    else
      {:error, %Redix.Error{message: message}} -> {:error, message}
      _                                        -> {:error, "Could not insert match list with fight result"}
    end
  end

  @spec get_match_list_with_fight_result(integer()) :: any()
  def get_match_list_with_fight_result(tournament_id) do
    conn = conn()

    with {:ok, _}                            <- Redix.command(conn, ["SELECT", 2]),
         {:ok, value} when not is_nil(value) <- Redix.command(conn, ["GET", tournament_id]),
         {match_list, _}                     <- Code.eval_string(value) do
      match_list
    else
      _ -> nil
    end
  end

  @spec get_match_list_with_fight_result_including_log(integer()) :: match_list()
  def get_match_list_with_fight_result_including_log(tournament_id) do
    tournament_id
    |> __MODULE__.get_match_list_with_fight_result()
    |> case do
      nil ->
        tournament_id
        |> __MODULE__.get_match_list_with_fight_result_log()
        # TODO: nilだったときのエラーハンドリング
        |> Map.get(:match_list_with_fight_result_str)
        |> Code.eval_string()
        |> elem(0)

      match_list -> match_list
    end
  end

  @spec delete_match_list_with_fight_result(integer()) :: {:ok, nil} | {:error, String.t()}
  def delete_match_list_with_fight_result(tournament_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
         {:ok, _} <- Redix.command(conn, ["SELECT", 2]),
         {:ok, _} <- Redix.command(conn, ["DEL", tournament_id]),
         {:ok, _} <- Redix.command(conn, ["EXEC"]) do
      {:ok, nil}
    else
      {:error, %Redix.Error{message: message}} -> {:error, message}
      _ -> {:error, "Could not delete match list with fight result"}
    end
  end

  @spec renew_match_list_with_fight_result(integer() | [integer()], integer()) :: {:ok, nil} | {:error, String.t()}
  def renew_match_list_with_fight_result(loser, tournament_id) do
    conn = conn()

    with {:ok, _}                                    <- Redix.command(conn, ["SELECT", 2]),
         {:ok, value} when value == 1                <- Redix.command(conn, ["SETNX", -tournament_id, 2]),
         {:ok, _}                                    <- Redix.command(conn, ["EXPIRE", -tournament_id, 20]),
         {:ok, _}                                    <- Redix.command(conn, ["SELECT", 2]),
         {:ok, value}                                <- Redix.command(conn, ["GET", tournament_id]),
         {match_list, _} when not is_nil(match_list) <- Code.eval_string(value),
         match_list                                  <- Tournamex.renew_match_list_with_loser(match_list, loser),
         bin                                         <- inspect(match_list, charlists: false),
         {:ok, _}                                    <- Redix.command(conn, ["DEL", tournament_id]),
         {:ok, _}                                    <- Redix.command(conn, ["SET", tournament_id, bin]),
         {:ok, _}                                    <- Redix.command(conn, ["DEL", -tournament_id]) do
      {:ok, nil}
    else
      {:error, %Redix.Error{message: message}} -> {:error, message}
      _                                        -> {:error, "Could not renew match list with fight result"}
    end
  end

  # 3. match_pending_list
  # Manages match pending list.
  # The list contains user_id of a user who pressed start_match and
  # the fight is not finished.

  @is_waiting_for_start "IsWaitingForStart"
  @is_waiting_for_coin_flip "IsWaitingForCoinFlip"
  # @should_choose_map "ShouldChooseMap"

  @spec insert_match_pending_list_table(integer(), integer()) :: {:ok, nil} | {:error, String.t()}
  def insert_match_pending_list_table(user_id, tournament_id) do
    # 大会タイプで分岐入れよう
    tournament = Tournaments.get_tournament(tournament_id)
    _pending_state = get_match_pending_list(user_id, tournament_id)

    should_flip_coin? = tournament.enabled_coin_toss

    key = if should_flip_coin? do
        @is_waiting_for_coin_flip
      else
        @is_waiting_for_start
      end

    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
         {:ok, _} <- Redix.command(conn, ["SELECT", 3]),
         {:ok, _} <- Redix.command(conn, ["HSET", tournament_id, user_id, key]),
         {:ok, _} <- Redix.command(conn, ["EXEC"]) do
      {:ok, nil}
    else
      {:error, %Redix.Error{message: message}} -> {:error, message}
      _ -> {:error, "Could not insert match pending list"}
    end
  end

  @spec get_match_pending_list(integer(), integer()) :: String.t() | nil
  def get_match_pending_list(user_id, tournament_id) do
    conn = conn()

    with {:ok, _}                            <- Redix.command(conn, ["SELECT", 3]),
         {:ok, value} when not is_nil(value) <- Redix.command(conn, ["HGET", tournament_id, user_id]) do
      value
    else
      _ -> nil
    end
  end

  @spec get_match_pending_list_of_tournament(integer()) :: any()
  def get_match_pending_list_of_tournament(tournament_id) do
    conn = conn()

    with {:ok, _}     <- Redix.command(conn, ["SELECT", 3]),
         {:ok, value} <- Redix.command(conn, ["HKEYS", tournament_id]) do
      value
    else
      _ -> nil
    end
  end

  @spec delete_match_pending_list(integer(), integer()) :: {:ok, nil} | {:error, String.t()}
  def delete_match_pending_list(user_id, tournament_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
         {:ok, _} <- Redix.command(conn, ["SELECT", 3]),
         {:ok, _} <- Redix.command(conn, ["HDEL", tournament_id, user_id]),
         {:ok, _} <- Redix.command(conn, ["EXEC"]) do
      {:ok, nil}
    else
      {:error, %Redix.Error{message: message}} -> {:error, message}
      _ -> {:error, "Could not delete match pending list"}
    end
  end

  @spec delete_match_pending_list_of_tournament(integer()) :: {:ok, nil} | {:error, String.t()}
  def delete_match_pending_list_of_tournament(tournament_id) do
    conn = conn()

    with {:ok, _}                         <- Redix.command(conn, ["SELECT", 3]),
         {:ok, value} when is_list(value) <- Redix.command(conn, ["HKEYS", tournament_id]),
         {:ok, _}                         <- do_delete_match_pending_list_of_tournament(conn, tournament_id, value) do
      {:ok, nil}
    else
      {:error, %Redix.Error{message: message}} -> {:error, message}
      _ -> {:error, "Could not delete match pending list of tournament"}
    end
  end

  defp do_delete_match_pending_list_of_tournament(conn, tournament_id, keys) do
    keys
    |> Enum.map(&String.to_integer(&1))
    |> Enum.map(&Redix.command(conn, ["HDEL", tournament_id, &1]))
    |> Enum.all?(&match?({:ok, _}, &1))
    |> Tools.boolean_to_tuple()
  end

  # 4. match_pending_list
  # Manages fight result.

  @spec insert_fight_result_table(integer(), integer(), boolean()) :: {:ok, nil} | {:error, String.t()}
  def insert_fight_result_table(user_id, tournament_id, is_win) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
         {:ok, _} <- Redix.command(conn, ["SELECT", 4]),
         {:ok, _} <- Redix.command(conn, ["HSET", tournament_id, user_id, is_win]),
         {:ok, _} <- Redix.command(conn, ["EXEC"]) do
      {:ok, nil}
    else
      {:error, %Redix.Error{message: message}} -> {:error, message}
      _ -> {:error, "Could not insert fight result"}
    end
  end

  @spec get_fight_result(integer(), integer()) :: boolean() | nil
  def get_fight_result(user_id, tournament_id) do
    conn = conn()

    with {:ok, _}                            <- Redix.command(conn, ["SELECT", 4]),
         {:ok, value} when not is_nil(value) <- Redix.command(conn, ["HGET", tournament_id, user_id]) do
      value
      |> Code.eval_string()
      |> elem(0)
    else
      _ -> nil
    end
  end

  @spec delete_fight_result(integer(), integer()) :: {:ok, nil} | {:error, String.t()}
  def delete_fight_result(user_id, tournament_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
         {:ok, _} <- Redix.command(conn, ["SELECT", 4]),
         {:ok, _} <- Redix.command(conn, ["HDEL", tournament_id, user_id]),
         {:ok, _} <- Redix.command(conn, ["EXEC"]) do
      {:ok, nil}
    else
      {:error, %Redix.Error{message: message}} -> {:error, message}
      _                                        -> {:error, "Could not delete fight result"}
    end
  end

  @spec delete_fight_result_of_tournament(integer()) :: {:ok, nil} | {:error, String.t()}
  def delete_fight_result_of_tournament(tournament_id) do
    conn = conn()

    with {:ok, _}                         <- Redix.command(conn, ["SELECT", 4]),
         {:ok, value} when is_list(value) <- Redix.command(conn, ["HKEYS", tournament_id]),
         {:ok, _}                         <- do_delete_fight_result_of_tournament(conn, tournament_id, value) do
      {:ok, nil}
    else
      {:error, %Redix.Error{message: message}} -> {:error, message}
      _                                        -> {:error, "Could not delete fight result of tournament"}
    end
  end

  # TODO: do_delete_match_pending_list_of_tournamentと共通処理で括れそう
  defp do_delete_fight_result_of_tournament(conn, tournament_id, keys) do
    keys
    |> Enum.map(&String.to_integer(&1))
    |> Enum.map(&Redix.command(conn, ["HDEL", tournament_id, &1]))
    |> Enum.all?(&match?({:ok, _}, &1))
    |> Tools.boolean_to_tuple()
  end

  # 5. duplicate_users
  # Manages duplicate users whose claims are same as their opponent.
  @spec add_duplicate_user_id(integer(), integer()) :: {:ok, nil} | {:error, String.t()}
  def add_duplicate_user_id(tournament_id, user_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
         {:ok, _} <- Redix.command(conn, ["SELECT", 5]),
         {:ok, _} <- Redix.command(conn, ["SADD", tournament_id, user_id]),
         {:ok, _} <- Redix.command(conn, ["EXEC"]) do
      {:ok, nil}
    else
      {:error, %Redix.Error{message: message}} -> {:error, message}
      _ -> {:error, "Could not add duplicate user id"}
    end
  end

  @doc """
  重複報告をしたユーザーリストを取得する。
  """
  @spec get_duplicate_users(integer()) :: [integer()]
  def get_duplicate_users(tournament_id) do
    conn = conn()

    with {:ok, _}                         <- Redix.command(conn, ["SELECT", 5]),
         {:ok, value} when is_list(value) <- Redix.command(conn, ["SMEMBERS", tournament_id]) do
      Enum.map(value, &String.to_integer(&1))
    else
      _ -> []
    end
  end

  @doc """
  redis上の重複報告者リストに入れられているユーザーを削除する。
  """
  @spec delete_duplicate_user(integer(), integer()) :: {:ok, nil} | {:error, String.t()}
  def delete_duplicate_user(tournament_id, user_id) do
    conn = conn()

    with {:ok, _}                                       <- Redix.command(conn, ["SELECT", 5]),
         {:ok, n}                                       <- Redix.command(conn, ["SCARD", tournament_id]),
         {:ok, user_id_list} when is_list(user_id_list) <- Redix.command(conn, ["SPOP", tournament_id, n]),
         {:ok, _}                                       <- do_delete_duplicate_users(conn, tournament_id, user_id, user_id_list) do
      {:ok, nil}
    else
      {:error, %Redix.Error{message: message}} -> {:error, message}
      _ -> {:error, "Could not delete duplicate user"}
    end
  end

  defp do_delete_duplicate_users(conn, tournament_id, user_id, user_id_list) do
    user_id_list
    |> Enum.reject(&(to_string(user_id) === to_string(&1)))
    |> Enum.map(&Redix.command(conn, ["SADD", tournament_id, &1]))
    |> Enum.all?(&match?({:ok, _}, &1))
    |> Tools.boolean_to_tuple()
  end

  @doc """
  与えられたtournament_idの重複報告者リストを削除する。
  """
  @spec delete_duplicate_users_all(integer()) :: {:ok, nil} | {:error, String.t()}
  def delete_duplicate_users_all(tournament_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["SELECT", 5]),
         {:ok, n} <- Redix.command(conn, ["SCARD", tournament_id]),
         {:ok, _} <- Redix.command(conn, ["SPOP", tournament_id, n]) do
      {:ok, nil}
    else
      {:error, %Redix.Error{message: message}} -> {:error, message}
      _ -> {:error, "Could not delete duplicate users all"}
    end
  end

  # 7. scores
  # Instead of fight result, we use scores for players fight result management.

  @doc """
  スコアを記録する
  """
  @spec insert_score(integer(), integer(), integer()) :: {:ok, nil} | {:error, String.t()}
  def insert_score(tournament_id, user_id, score) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
         {:ok, _} <- Redix.command(conn, ["SELECT", 7]),
         {:ok, _} <- Redix.command(conn, ["HSET", tournament_id, user_id, score]),
         {:ok, _} <- Redix.command(conn, ["EXEC"]) do
      {:ok, nil}
    else
      {:error, %Redix.Error{message: message}} -> {:error, message}
      _ -> {:error, "Could not insert score"}
    end
  end

  @doc """
  ユーザーのその大会でのスコアを取得する
  """
  @spec get_score(integer(), integer()) :: integer() | nil
  def get_score(tournament_id, user_id) do
    conn = conn()

    with {:ok, _}                            <- Redix.command(conn, ["SELECT", 7]),
         {:ok, value} when not is_nil(value) <- Redix.command(conn, ["HGET", tournament_id, user_id]) do
      value
      |> Code.eval_string()
      |> elem(0)
    else
      _ -> nil
    end
  end

  @spec delete_score(integer(), integer()) :: {:ok, nil} | {:error, String.t()}
  def delete_score(tournament_id, user_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
         {:ok, _} <- Redix.command(conn, ["SELECT", 7]),
         {:ok, _} <- Redix.command(conn, ["HDEL", tournament_id, user_id]),
         {:ok, _} <- Redix.command(conn, ["EXEC"]) do
      {:ok, nil}
    else
      {:error, %Redix.Error{message: message}} -> {:error, message}
      _ -> {:error, "Could not delete score"}
    end
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

    with {:ok, _}     <- Redix.command(conn, ["SELECT", 8]),
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

  @spec delete_ban_order(integer(), integer()) :: {:ok, nil} | {:error, String.t()}
  def delete_ban_order(tournament_id, id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
         {:ok, _} <- Redix.command(conn, ["SELECT", 8]),
         {:ok, _} <- Redix.command(conn, ["HDEL", tournament_id, id]),
         {:ok, _} <- Redix.command(conn, ["EXEC"]) do
      {:ok, nil}
    else
      {:error, %Redix.Error{message: message}} -> {:error, message}
      _ -> {:error, "Could not delete ban order"}
    end
  end

  # 9. a/d state
  # attacker side or defender side.
  def insert_is_attacker_side(id, tournament_id, is_attacker_side) when is_boolean(is_attacker_side) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
         {:ok, _} <- Redix.command(conn, ["SELECT", 9]),
         {:ok, _} <- Redix.command(conn, ["HSET", tournament_id, id, is_attacker_side]),
         {:ok, _} <- Redix.command(conn, ["EXEC"]) do
      {:ok, nil}
    else
      {:error, %Redix.Error{message: message}} -> {:error, message}
      _ -> {:error, "Could not insert attacker side information"}
    end
  end

  @spec is_attacker_side?(integer(), integer()) :: boolean() | nil
  def is_attacker_side?(id, tournament_id) do
    conn = conn()

    with {:ok, _}                            <- Redix.command(conn, ["SELECT", 9]),
         {:ok, value} when not is_nil(value) <- Redix.command(conn, ["HGET", tournament_id, id]) do
      value
      |> Code.eval_string()
      |> elem(0)
    else
      _ -> nil
    end
  end

  @spec delete_is_attacker_side(integer(), integer()) :: {:ok, nil} | {:error, String.t()}
  def delete_is_attacker_side(id, tournament_id) do
    conn = conn()

    with {:ok, _} <- Redix.command(conn, ["MULTI"]),
         {:ok, _} <- Redix.command(conn, ["SELECT", 9]),
         {:ok, _} <- Redix.command(conn, ["HDEL", tournament_id, id]),
         {:ok, _} <- Redix.command(conn, ["EXEC"]) do
      {:ok, nil}
    else
      {:error, %Redix.Error{message: message}} -> {:error, message}
      _ -> {:error, "Could not delete attacker side information"}
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

  @spec create_best_of_x_tournament_match_log(map()) :: {:ok, BestOfXTournamentMatchLog.t()} | {:error, Ecto.Changeset.t()}
  def create_best_of_x_tournament_match_log(attrs \\ %{}) do
    %BestOfXTournamentMatchLog{}
    |> BestOfXTournamentMatchLog.changeset(attrs)
    |> Repo.insert()
  end

  # NOTE: round robin log
  @spec create_round_robin_log(map()) :: {:ok, RoundRobinLog.t()} | {:error, Ecto.Changeset.t() | String.t()}
  def create_round_robin_log(attrs \\ %{}) do
    %RoundRobinLog{}
    |> RoundRobinLog.changeset(attrs)
    |> Repo.insert()
  end

  # NOTE: match list with fight result log.

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

  # NOTE: 個人大会スタート時に使用する関数群
  # HACK

  @spec start_basic(integer(), Tournament.t()) :: {:ok, match_list(), match_list_with_fight_result()} | {:error, any()}
  def start_basic(_master_id, tournament) do
    case Tournaments.start(tournament) do
      {:ok, _}        -> make_basic_matches(tournament.id)
      {:error, error} -> {:error, error}
    end
  end

  @spec start_flipban(integer(), Tournament.t()) :: {:ok, match_list(), nil}
  def start_flipban(_master_id, tournament) do
    with {:ok, _} <- Tournaments.start(tournament),
         {:ok, match_list} <- make_flipban_matches(tournament) do
      {:ok, match_list, nil}
    else
      error -> error
    end
  end

  defp make_basic_matches(tournament_id) do
    match_list = __MODULE__.get_match_list(tournament_id)

    if is_nil(match_list) do
      tournament_id
      |> Tournaments.get_entrants()
      |> Enum.map(&Map.get(&1, :user_id))
      |> Tournaments.generate_matchlist()
    else
      {:ok, match_list}
    end
    ~> {:ok, match_list}

    tournament = Tournaments.get_tournament(tournament_id)
    count = tournament.count

    Tournaments.initialize_rank(match_list, count, tournament_id)
    insert_match_list(match_list, tournament_id)
    match_list_with_fight_result = Tournamex.initialize_match_list_with_fight_result(match_list)

    match_list_with_fight_result
    |> List.flatten()
    |> Enum.reduce(match_list_with_fight_result, fn x, acc ->
      user = Accounts.get_user(x["user_id"])

      acc
      |> Tournaments.put_value_on_brackets(user.id, %{"name" => user.name})
      |> Tournaments.put_value_on_brackets(user.id, %{"win_count" => 0})
      |> Tournaments.put_value_on_brackets(user.id, %{"icon_path" => user.icon_path})
    end)
    |> insert_match_list_with_fight_result(tournament_id)

    {:ok, match_list, match_list_with_fight_result}
  end

  defp make_flipban_matches(tournament) do
    tournament.id
    |> Tournaments.get_entrants()
    |> Enum.map(&(&1.user_id))
    |> Tournaments.generate_matchlist()
    ~> {:ok, match_list}
    |> elem(1)
    |> insert_match_list(tournament.id)

    count = tournament.count
    Tournaments.initialize_rank(match_list, count, tournament.id)

    match_list_with_fight_result = Tournamex.initialize_match_list_with_fight_result(match_list)

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

  # NOTE: チーム大会スタートに関する関数群

  @spec start_team_flipban(Tournament.t()) :: {:ok, match_list(), match_list_with_fight_result()} | {:error, String.t(), nil}
  def start_team_flipban(tournament) do
    tournament
    |> Tournaments.start()
    |> case do
      {:ok, _}        -> generate_team_flipban_matches(tournament)
      {:error, error} -> {:error, error, nil}
    end
  end

  defp generate_team_flipban_matches(tournament) do
    match_list = __MODULE__.get_match_list(tournament.id)
    teams = Tournaments.get_confirmed_teams(tournament.id)

    if is_nil(match_list) do
      teams
      |> Enum.map(&Map.get(&1, :id))
      |> Tournaments.generate_matchlist()
      |> elem(1)
      ~> match_list

      {:ok, teams, match_list}
    else
      {:ok, teams, match_list}
    end
    ~> {:ok, teams, match_list}

    __MODULE__.insert_match_list(match_list, tournament.id)
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
      |> Tournaments.load_leader()
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

  def start_team_flipban_round_robin(%Tournament{id: tournament_id} = tournament) do
    with {:ok, _}          <- Tournaments.start(tournament),
         {:ok, match_list} <- generate_team_flipban_roundrobin_matches(tournament),
         match_list        <- %{"rematch_index" => 0, "current_match_index" => 0, "match_list" => match_list},
         {:ok, nil}        <- __MODULE__.insert_match_list(match_list, tournament_id),
         {:ok, _}          <- __MODULE__.change_states_in_match_list_of_round_robin(tournament),
         {:ok, _}          <- Tournaments.set_proper_round_robin_team_rank(match_list, tournament_id) do
      {:ok, nil, nil}
    else
      {:error, error} -> {:error, error, nil}
    end
  end

  defp generate_team_flipban_roundrobin_matches(tournament) do
    tournament.id
    |> Tournaments.get_confirmed_teams()
    |> Enum.map(&Map.get(&1, :id))
    |> RoundRobin.generate_match_list()
  end

  @spec start_free_for_all(Tournament.t()) :: {:ok, nil, nil} | {:error, String.t() | nil}
  def start_free_for_all(tournament) do
    # 不必要なチームを除外したら対戦カードを生成していく
    # with ffa_info when not is_nil(ffa_info) <- FreeForAll.get_freeforall_information_by_tournament_id(tournament.id),
    #      {:ok, nil}                         <- FreeForAll.truncate_excess_members(tournament, ffa_info),
    #      {:ok, nil}                         <- FreeForAll.initialize_round_tables(tournament, 0),
    #      {:ok, _}                           <- Tournaments.start(tournament),
    #      {:ok, _}                           <- FreeForAll.create_status(%{tournament_id: tournament.id, current_match_index: 0}) do
    #   {:ok, nil, nil}
    # else
    #   # NOTE: tmp
    #   {:error, error} -> {:ok, nil, nil}
    #   _               -> {:ok, nil, nil}
    # end
    ffa_info = FreeForAll.get_freeforall_information_by_tournament_id(tournament.id)
    FreeForAll.truncate_excess_members(tournament, ffa_info)
    FreeForAll.initialize_round_tables(tournament, 0)
    Tournaments.start(tournament)
    FreeForAll.create_status(%{tournament_id: tournament.id, current_match_index: 0})
    {:ok, nil, nil}
  end

  # NOTE: 一人の人を除外する処理
  def change_states_in_match_list_of_round_robin(tournament) do
    %{"match_list" => match_list, "current_match_index" => current_match_index} = __MODULE__.get_match_list(tournament.id)

    matches = Enum.at(match_list, current_match_index)

    if is_nil(matches) do
      {:ok, nil}
    else
      matches
      |> Enum.map(fn {match, _} ->
        match
        |> __MODULE__.cut_out_numbers_from_match_str_of_round_robin()
        |> case do
          [_, _] -> {:ok, nil}
          [num]  -> do_change_states_in_match_list_of_round_robin(tournament, num)
          _      -> raise "Invalid match str"
        end
      end)
      |> Enum.all?(&match?({:ok, _}, &1))
      |> Tools.boolean_to_tuple()
    end
  end

  defp do_change_states_in_match_list_of_round_robin(%Tournament{is_team: true, id: tournament_id, rule: rule}, team_id) do
    team_id
    |> Tournaments.get_leader()
    |> Map.get(:user_id)
    |> Rules.adapt_keyname(tournament_id)
    ~> keyname

    case rule do
      "flipban_roundrobin" -> FlipBanRoundRobin.trigger!(keyname, FlipBanRoundRobin.waiting_for_next_match_trigger())
      _                    -> {:error, "Invalid State"}
    end
  end

  @doc """
  Get necessary id for tournament progress.
  """
  @spec get_necessary_id(integer(), integer()) :: integer() | nil
  def get_necessary_id(tournament_id, user_id) do
    tournament_id
    |> Tournaments.get_tournament_including_logs()
    |> case do
      {:ok, %Tournament{} = tournament}    -> do_get_necessary_id(tournament, user_id)
      {:ok, %TournamentLog{} = tournament} -> do_get_necessary_log_id(tournament, user_id)
      _                                    -> nil
    end
  end

  defp do_get_necessary_id(%Tournament{master_id: master_id, id: tournament_id, is_team: is_team}, user_id) when master_id == user_id do
    if Tournaments.is_participant?(tournament_id, user_id) and is_team do
      tournament_id
      |> Tournaments.get_team_by_tournament_id_and_user_id(user_id)
      |> get_team_id()
    else
      user_id
    end
  end
  defp do_get_necessary_id(%Tournament{id: id, is_team: true}, user_id) do
    id
    |> Tournaments.get_team_by_tournament_id_and_user_id(user_id)
    |> get_team_id()
  end
  defp do_get_necessary_id(_, user_id), do: user_id

  defp get_team_id(%Team{id: id}), do: id
  defp get_team_id(_), do: nil

  defp do_get_necessary_log_id(%TournamentLog{master_id: master_id}, user_id) when master_id == user_id, do: user_id
  defp do_get_necessary_log_id(%TournamentLog{tournament_id: id, is_team: true}, user_id) do
    id
    |> Log.get_team_log_by_tournament_id_and_user_id(user_id)
    |> get_team_log_id()
  end
  defp do_get_necessary_log_id(_, user_id), do: user_id

  defp get_team_log_id(%TeamLog{team_id: id}), do: id
  defp get_team_log_id(_), do: nil

  def create_team_win_count(attrs) do
    %TeamWinCount{}
    |> TeamWinCount.changeset(attrs)
    |> Repo.insert()
  end

  def get_team_win_count_by_team_id(team_id) do
    TeamWinCount
    |> where([twc], twc.team_id == ^team_id)
    |> Repo.one()
  end

  def update_team_win_count_by_team_id(team_id, attrs) do
    team_id
    |> __MODULE__.get_team_win_count_by_team_id()
    |> TeamWinCount.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  RoundRobinのmatch_strから数字を切り出す関数
  """
  def cut_out_numbers_from_match_str_of_round_robin(match_str) when is_binary(match_str) do
    match_str
    |> String.split("-")
    |> Enum.reject(&is_nil(&1))
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&String.to_integer(&1))
  end
  def cut_out_numbers_from_match_str_of_round_robin(_), do: []
end

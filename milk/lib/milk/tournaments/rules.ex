defmodule Milk.Tournaments.Rules do
  @moduledoc """
  大会で使用するルールに関するモジュール。
  """
  import Common.Sperm

  alias Common.Tools
  alias Milk.Tournaments
  alias Milk.Tournaments.{
    Progress,
    Tournament
  }
  alias Milk.Tournaments.Rules.{
    Basic,
    FlipBan,
    FlipBanRoundRobin
  }

  @spec adapt_keyname(integer(), integer()) :: String.t()
  def adapt_keyname(user_id, tournament_id), do: "user:#{user_id}_tournament:#{tournament_id}"

  @doc """
  オートマトンの動作がredisに存在していなければ定義する
  """
  @spec initialize_state_machine(Tournament.t()) :: :ok | :error
  def initialize_state_machine(%Tournament{rule: rule, is_team: is_team}) do
    case rule do
      "basic"              -> Basic.define_dfa!(is_team: is_team)
      "flipban"            -> FlipBan.define_dfa!(is_team: is_team)
      "flipban_roundrobin" -> FlipBanRoundRobin.define_dfa!(is_team: is_team)
      _         -> :error
    end
  end

  @doc """
  大会作成時に運営陣（master, assistant）のオートマトンを初期化する
  """
  @spec initialize_master_states(Tournament.t()) :: {:ok, nil}
  def initialize_master_states(%Tournament{id: tournament_id, rule: rule, is_team: is_team}) do
    tournament_id
    |> Tournaments.get_masters()
    |> Enum.map(fn user ->
      keyname = __MODULE__.adapt_keyname(user.id, tournament_id)

      case rule do
        "basic"              -> Basic.build_dfa_instance(keyname, is_team: is_team)
        "flipban"            -> FlipBan.build_dfa_instance(keyname, is_team: is_team)
        "flipban_roundrobin" -> FlipBanRoundRobin.build_dfa_instance(keyname, is_team: is_team)
        _                    -> raise "Invalid tournament rule"
      end
    end)
    |> Enum.all?(&(&1 == "OK"))
    |> Tools.boolean_to_tuple()
  end

  @spec start_master_states!(Tournament.t()) :: {:ok, Tournament.t()} | {:error, String.t()}
  def start_master_states!(tournament) do
    with {:ok, _}   <- start_master_state!(tournament),
         {:ok, nil} <- start_assistant_states!(tournament) do
      {:ok, tournament}
    else
      error -> error
    end
  end

  @spec start_master_state!(Tournament.t()) :: {:ok, any()} | {:error, String.t()}
  defp start_master_state!(%Tournament{id: tournament_id, rule: rule, master_id: master_id}) do
    tournament_id
    |> Tournaments.is_participant?(master_id)
    |> if do
      {:ok, nil}
    else
      keyname = __MODULE__.adapt_keyname(master_id, tournament_id)

      case rule do
        "basic"   -> Basic.trigger!(keyname, Basic.manager_trigger())
        "flipban" -> FlipBan.trigger!(keyname, FlipBan.manager_trigger())
        _         -> {:error, "Invalid tournament rule"}
      end
    end
  end

  @spec start_assistant_states!(Tournament.t()) :: {:ok, nil} | {:error, nil}
  defp start_assistant_states!(%Tournament{id: tournament_id, rule: rule}) do
    tournament_id
    |> Tournaments.get_assistants()
    |> Enum.map(fn assistant ->
      keyname = __MODULE__.adapt_keyname(assistant.user_id, tournament_id)

      case rule do
        "basic"   -> Basic.trigger!(keyname, Basic.assistant_trigger())
        "flipban" -> FlipBan.trigger!(keyname, FlipBan.assistant_trigger())
      end
    end)
    |> Enum.all?(&match?({:ok, _}, &1))
    |> Tools.boolean_to_tuple()
  end

  @doc """
  コイントスを行ったユーザーのオートマトン状態遷移
  ShouldFlipCoin -> IsWaitingForFlip
  """
  @spec change_state_on_flip_coin(Tournament.t(), integer()) :: {:ok, any()} | {:error, String.t()}
  def change_state_on_flip_coin(%Tournament{rule: rule, id: tournament_id}, user_id) do
    keyname = __MODULE__.adapt_keyname(user_id, tournament_id)

    case rule do
      "flipban" -> FlipBan.trigger!(keyname, FlipBan.flip_trigger())
      _         -> {:error, "Invalid tournament rule"}
    end
  end

  @doc """
  マップをBANしたときのオートマトン状態遷移
  1回目:
    ShouldBanMap     -> ShouldObserveBan
    ShouldObserveBan -> ShouldBanMap
  2回目:
    ShouldBanMap     -> ShouldObserveChoose
    ShouldObserveBan -> ShouldChooseMap
  """
  @spec change_state_on_ban(Tournament.t(), integer(), integer()) :: {:ok, nil} | {:error, String.t()}
  def change_state_on_ban(%Tournament{rule: rule, id: tournament_id, is_team: is_team}, user_id, opponent_id) do
    id = Progress.get_necessary_id(tournament_id, user_id)
    is_head = Tournaments.is_head_of_coin?(tournament_id, id, opponent_id)

    # TODO: match_listの中身をteam_idからleader_idに変えたら不要になる処理
    if is_team do
      opponent_id
      |> Tournaments.get_leader()
      |> Map.get(:user_id)
    else
      opponent_id
    end
    ~> opponent_id

    keyname = __MODULE__.adapt_keyname(user_id, tournament_id)
    opponent_keyname = __MODULE__.adapt_keyname(opponent_id, tournament_id)

    # NOTE: 自分のコインが裏で、banを終えていた場合遷移を変える
    do_change_state_on_ban(is_head, rule, keyname, opponent_keyname)
  end

  defp do_change_state_on_ban(_, rule, _, _) when rule != "flipban", do: {:error, "Invalid tournament rule"}
  defp do_change_state_on_ban(true, _, keyname, opponent_keyname) do
    with {:ok, _} <- FlipBan.trigger!(keyname, FlipBan.observe_ban_map_trigger()),
         {:ok, _} <- FlipBan.trigger!(opponent_keyname, FlipBan.ban_map_trigger()) do
      {:ok, nil}
    else
      error -> error
    end
  end
  defp do_change_state_on_ban(false, _, keyname, opponent_keyname) do
    with {:ok, _} <- FlipBan.trigger!(keyname, FlipBan.observe_choose_map_trigger()),
         {:ok, _} <- FlipBan.trigger!(opponent_keyname, FlipBan.choose_map_trigger()) do
      {:ok, nil}
    else
      error -> error
    end
  end

  @doc """
  マップを選択した際のオートマトン状態遷移
  ShouldChooseMap     -> ShouldObserveA/D
  ShouldObserveChoose -> ShouldChooseA/D
  """
  @spec change_state_on_choose_map(Tournament.t(), integer(), integer()) :: {:ok, nil} | {:error, String.t()}
  def change_state_on_choose_map(%Tournament{rule: rule, is_team: is_team, id: tournament_id}, user_id, opponent_id) do
    # TODO: match_listの中身をteam_idからleader_idに変えたら不要になる処理
    if is_team do
      opponent_id
      |> Tournaments.get_leader()
      |> Map.get(:user_id)
    else
      opponent_id
    end
    ~> opponent_id

    keyname = __MODULE__.adapt_keyname(user_id, tournament_id)
    opponent_keyname = __MODULE__.adapt_keyname(opponent_id, tournament_id)

    do_change_state_on_choose_map(rule, keyname, opponent_keyname)
  end

  defp do_change_state_on_choose_map(rule, _, _) when rule != "flipban", do: {:error, "Invalid tournament rule"}
  defp do_change_state_on_choose_map(_, keyname, opponent_keyname) do
    with {:ok, _} <- FlipBan.trigger!(keyname, FlipBan.observe_choose_ad_trigger()),
         {:ok, _} <- FlipBan.trigger!(opponent_keyname, FlipBan.choose_ad_trigger()) do
      {:ok, nil}
    else
      error -> error
    end
  end

  @doc """
  A/D選択をした際のオートマトン状態遷移
  ShouldChooseA/D  -> IsPending
  ShouldObserveA/D -> IsPending
  """
  @spec change_state_on_choose_ad(Tournament.t(), integer(), integer()) :: {:ok, nil} | {:error, String.t()}
  def change_state_on_choose_ad(%Tournament{rule: rule, is_team: is_team, id: tournament_id}, user_id, opponent_id) do
    # TODO: match_listの中身をteam_idからleader_idに変えたら不要になる処理
    if is_team do
      opponent_id
      |> Tournaments.get_leader()
      |> Map.get(:user_id)
    else
      opponent_id
    end
    ~> opponent_id

    keyname = __MODULE__.adapt_keyname(user_id, tournament_id)
    opponent_keyname = __MODULE__.adapt_keyname(opponent_id, tournament_id)

    do_change_state_on_choose_ad(rule, keyname, opponent_keyname)
  end

  defp do_change_state_on_choose_ad(rule, _, _) when rule != "flipban", do: {:error, "Invalid tournament rule"}
  defp do_change_state_on_choose_ad(_, keyname, opponent_keyname) do
    with {:ok, _} <- FlipBan.trigger!(keyname, FlipBan.pend_trigger()),
         {:ok, _} <- FlipBan.trigger!(opponent_keyname, FlipBan.pend_trigger()) do
      {:ok, nil}
    else
      error -> error
    end
  end
end

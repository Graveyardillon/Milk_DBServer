defmodule Milk.Tournaments.Rules.FlipBan do
  @moduledoc """
  コイントス＆マップBANルールにおける処理が記述してあるモジュール
  モジュール自身の関数を参照することが多く、記述量が増加する割に情報量は増えないので__MODULE__の記述は省略している。
  """
  @behaviour Milk.Tournaments.Rules.Rule

  alias Dfa.Predefined
  alias Milk.Tournaments.Rules.Rule

  @db_index Rule.db_index()

  @impl Rule
  def machine_name(true),  do: "flipban_team"
  def machine_name(false), do: "flipban"

  @impl Rule
  def define_dfa!(opts \\ []) do
    is_team = Keyword.get(opts, :is_team, true)
    machine_name = Keyword.get(opts, :machine_name, machine_name(is_team))

    machine_name
    |> Predefined.exists?(@db_index)
    |> do_define_dfa!(opts)
  end

  @spec do_define_dfa!(boolean(), Rule.opts()) :: :ok
  defp do_define_dfa!(true, _), do: :ok
  defp do_define_dfa!(false, opts) do
    is_team = Keyword.get(opts, :is_team, true)
    machine_name = Keyword.get(opts, :machine_name, machine_name(is_team))

    # NOTE: チーム戦のときはis_memberのstateが追加される
    if is_team, do: Predefined.on!(machine_name, @db_index, member_trigger(), is_not_started(), is_member())

    Predefined.on!(machine_name, @db_index, start_trigger(), is_not_started(), should_flip_coin())
    Predefined.on!(machine_name, @db_index, manager_trigger(), is_not_started(), is_manager())
    Predefined.on!(machine_name, @db_index, assistant_trigger(), is_not_started(), is_assistant())
    Predefined.on!(machine_name, @db_index, flip_trigger(), should_flip_coin(), is_waiting_for_coin_flip())
    Predefined.on!(machine_name, @db_index, ban_map_trigger(), is_waiting_for_coin_flip(), should_ban_map())
    Predefined.on!(machine_name, @db_index, observe_ban_map_trigger(), is_waiting_for_coin_flip(), should_observe_ban())
    Predefined.on!(machine_name, @db_index, observe_ban_map_trigger(), should_ban_map(), should_observe_ban())
    Predefined.on!(machine_name, @db_index, ban_map_trigger(), should_observe_ban(), should_ban_map())
    Predefined.on!(machine_name, @db_index, choose_map_trigger(), should_observe_ban(), should_choose_map())
    Predefined.on!(machine_name, @db_index, observe_choose_map_trigger(), should_ban_map(), should_observe_choose())
    Predefined.on!(machine_name, @db_index, choose_ad_trigger(), should_observe_choose(), should_choose_ad())
    Predefined.on!(machine_name, @db_index, observe_choose_ad_trigger(), should_choose_map(), should_observe_ad())
    Predefined.on!(machine_name, @db_index, pend_trigger(), should_choose_ad(), is_pending())
    Predefined.on!(machine_name, @db_index, pend_trigger(), should_observe_ad(), is_pending())
    Predefined.on!(machine_name, @db_index, lose_trigger(), is_pending(), is_loser())
    Predefined.on!(machine_name, @db_index, alone_trigger(), is_pending(), is_alone())
    Predefined.on!(machine_name, @db_index, next_trigger(), is_alone(), should_flip_coin())
    Predefined.on!(machine_name, @db_index, next_trigger(), is_pending(), should_flip_coin())

    opts
    |> list_states()
    |> Enum.reject(&(&1 == is_finished()))
    |> Enum.each(&Predefined.on!(machine_name, @db_index, finish_trigger(), &1, is_finished()))
  end

  @impl Rule
  def build_dfa_instance(instance_name, opts \\ []) do
    is_team = Keyword.get(opts, :is_team, true)
    machine_name = machine_name(is_team)

    Predefined.initialize!(instance_name, machine_name, @db_index, is_not_started())
  end

  @impl Rule
  def state!(instance_name), do: Predefined.state!(instance_name, @db_index)

  @impl Rule
  def trigger!(instance_name, trigger), do: Predefined.trigger!(instance_name, @db_index, trigger)

  @impl Rule
  def list_states(opts \\ []) do
    opts
    |> unfiltered_list_states()
    |> Enum.reject(&is_nil(&1))
  end

  @spec unfiltered_list_states(Rule.opts()) :: [String.t()]
  defp unfiltered_list_states(opts) do
    [
      is_not_started(),
      if Keyword.get(opts, :is_team, true) do
        is_member()
      end,
      is_manager(),
      is_assistant(),
      should_flip_coin(),
      is_waiting_for_coin_flip(),
      should_ban_map(),
      should_observe_ban(),
      should_choose_map(),
      should_observe_choose(),
      should_choose_ad(),
      should_observe_ad(),
      is_pending(),
      is_loser(),
      is_alone(),
      is_finished()
    ]
  end

  #
  # =====================================
  # 大会の状態について取得するための関数群
  # =====================================
  #

  @spec is_not_started() :: String.t()
  def is_not_started(), do: "IsNotStarted"

  @spec is_member() :: String.t()
  def is_member(), do: "IsMember"

  @spec is_manager() :: String.t()
  def is_manager(), do: "IsManager"

  @spec is_assistant() :: String.t()
  def is_assistant(), do: "IsAssistant"

  @spec should_flip_coin() :: String.t()
  def should_flip_coin(), do: "ShouldFlipCoin"

  @spec is_waiting_for_coin_flip() :: String.t()
  def is_waiting_for_coin_flip(), do: "IsWaitingForCoinFlip"

  @spec should_ban_map() :: String.t()
  def should_ban_map(), do: "ShouldBanMap"

  @spec should_observe_ban() :: String.t()
  def should_observe_ban(), do: "ShouldObserveBan"

  @spec should_choose_map() :: String.t()
  def should_choose_map(), do: "ShouldChooseMap"

  @spec should_observe_choose() :: String.t()
  def should_observe_choose(), do: "ShouldObserveChoose"

  @spec should_choose_ad() :: String.t()
  def should_choose_ad(), do: "ShouldChooseA/D"

  @spec should_observe_ad() :: String.t()
  def should_observe_ad(), do: "ShouldObserveA/D"

  @spec is_pending() :: String.t()
  def is_pending(), do: "IsPending"

  @spec is_loser() :: String.t()
  def is_loser(), do: "IsLoser"

  @spec is_alone() :: String.t()
  def is_alone(), do: "IsAlone"

  @spec is_finished() :: String.t()
  def is_finished(), do: "IsFinished"

  #
  # =========================================================
  # 大会の状態を遷移させるためのトリガーを取得するための関数群
  # =========================================================
  #

  @spec start_trigger() :: String.t()
  def start_trigger(), do: "start"

  @spec member_trigger() :: String.t()
  def member_trigger(), do: "member"

  @spec manager_trigger() :: String.t()
  def manager_trigger(), do: "manager"

  @spec assistant_trigger() :: String.t()
  def assistant_trigger(), do: "assistant"

  @spec flip_trigger() :: String.t()
  def flip_trigger(), do: "flip"

  @spec ban_map_trigger() :: String.t()
  def ban_map_trigger(), do: "ban_map"

  @spec observe_ban_map_trigger() :: String.t()
  def observe_ban_map_trigger(), do: "observe_ban"

  @spec choose_map_trigger() :: String.t()
  def choose_map_trigger(), do: "choose_map"

  @spec observe_choose_map_trigger() :: String.t()
  def observe_choose_map_trigger(), do: "observe_choose_map"

  @spec choose_ad_trigger() :: String.t()
  def choose_ad_trigger(), do: "choose_ad"

  @spec observe_choose_ad_trigger() :: String.t()
  def observe_choose_ad_trigger(), do: "observe_choose_ad_trigger"

  @spec pend_trigger() :: String.t()
  def pend_trigger(), do: "pend"

  @spec lose_trigger() :: String.t()
  def lose_trigger(), do: "lose"

  @spec alone_trigger() :: String.t()
  def alone_trigger(), do: "alone"

  @spec next_trigger() :: String.t()
  def next_trigger(), do: "next"

  @spec finish_trigger() :: String.t()
  def finish_trigger(), do: "finish"
end

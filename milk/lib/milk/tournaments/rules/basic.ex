defmodule Milk.Tournaments.Rules.Basic do
  @moduledoc """
  コイントスなどがなく、単なる勝敗報告しかしない場合のオートマトン
  """
  @behaviour Milk.Tournaments.Rules.Rule

  alias Dfa.Predefined
  alias Milk.Tournaments.Rules.Rule

  @db_index Rule.db_index()

  @impl Rule
  def machine_name(true),  do: "basic_team"
  def machine_name(false), do: "basic"

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

    if is_team, do: Predefined.on!(machine_name, @db_index, member_trigger(), is_not_started(), is_member())

    Predefined.on!(machine_name, @db_index, start_trigger(), is_not_started(), should_start_match())
    Predefined.on!(machine_name, @db_index, manager_trigger(), is_not_started(), is_manager())
    Predefined.on!(machine_name, @db_index, assistant_trigger(), is_not_started(), is_assistant())
    Predefined.on!(machine_name, @db_index, start_match_trigger(), should_start_match(), is_waiting_for_start_match())
    Predefined.on!(machine_name, @db_index, pend_trigger(), is_waiting_for_start_match(), is_pending())
    Predefined.on!(machine_name, @db_index, lose_trigger(), is_pending(), is_loser())
    Predefined.on!(machine_name, @db_index, alone_trigger(), is_pending(), is_alone())
    Predefined.on!(machine_name, @db_index, next_trigger(), is_alone(), should_start_match())
    Predefined.on!(machine_name, @db_index, next_trigger(), is_pending(), should_start_match())

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
  def destroy_dfa_instance(instance_name, opts \\ []) do
    Predefined.deinitialize!(instance_name, @db_index, opts)
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

  @spec unfiltered_list_states(Rule.list_state_opts()) :: [String.t()]
  defp unfiltered_list_states(opts) do
    [
      is_not_started(),
      if Keyword.get(opts, :is_team, true) do
        is_member()
      end,
      is_manager(),
      is_assistant(),
      should_start_match(),
      is_waiting_for_start_match(),
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

  @spec should_start_match() :: String.t()
  def should_start_match(), do: "ShouldStartMatch"

  @spec is_waiting_for_start_match() :: String.t()
  def is_waiting_for_start_match(), do: "IsWaitingForStartMatch"

  @spec is_pending() :: String.t()
  def is_pending(), do: "IsPending"

  @spec is_waiting_scoreinput() :: String.t()
  def is_waiting_scoreinput(), do: "IsWaitingScoreInput"

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

  @spec start_match_trigger() :: String.t()
  def start_match_trigger(), do: "start_match"

  @spec pend_trigger() :: String.t()
  def pend_trigger(), do: "pend"

  @spec waiting_scoreinput_trigger() :: String.t()
  def waiting_scoreinput_trigger(), do: "waiting_scoreinput"

  @spec lose_trigger() :: String.t()
  def lose_trigger(), do: "lose"

  @spec alone_trigger() :: String.t()
  def alone_trigger(), do: "alone"

  @spec next_trigger() :: String.t()
  def next_trigger(), do: "next"

  @spec finish_trigger() :: String.t()
  def finish_trigger(), do: "finish"
end

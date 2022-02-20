defmodule Milk.Tournaments.Rules.FreeForAll do
  @moduledoc """
  FreeForAllに関する記述
  """
  import Ecto.Query, warn: false

  alias Milk.Tournaments.Rules.FreeForAll.Information
  alias Milk.Tournaments.Tournament
  alias Milk.{
    Repo,
    Tournaments
  }

  @behaviour Milk.Tournaments.Rules.Rule

  alias Dfa.Predefined
  alias Milk.Tournaments.Rules.Rule

  @db_index Rule.db_index()
  @ver "1.0.0"

  @impl Rule
  def machine_name(true),  do: "freeforall_team-ver.#{@ver}"
  def machine_name(false), do: "freeforall-ver.#{@ver}"

  @impl Rule
  def define_dfa!(opts \\ []) do
    is_team = Keyword.get(opts, :is_team, true)
    machine_name = Keyword.get(opts, :machine_name, machine_name(is_team))

    machine_name
    |> Predefined.exists?(@db_index)
    |> do_define_dfa!(opts)
  end

  defp do_define_dfa!(true, _), do: :ok
  defp do_define_dfa!(false, opts) do
    is_team = Keyword.get(opts, :is_team, true)
    machine_name = Keyword.get(opts, :machine_name, machine_name(is_team))

    if is_team, do: Predefined.on!(machine_name, @db_index, member_trigger(), is_not_started(), is_member())

    Predefined.on!(machine_name, @db_index, start_trigger(),                is_not_started(),             should_input_score())
    Predefined.on!(machine_name, @db_index, manager_trigger(),              is_not_started(),             is_manager())
    Predefined.on!(machine_name, @db_index, assistant_trigger(),            is_not_started(),             is_assistant())
    Predefined.on!(machine_name, @db_index, should_input_score_trigger(),   should_input_score(),         should_input_score())
    Predefined.on!(machine_name, @db_index, wait_for_score_input_trigger(), should_input_score(),         is_waiting_for_score_input())
    Predefined.on!(machine_name, @db_index, wait_for_next_match_trigger(),  should_input_score(),         is_waiting_for_next_match())
    Predefined.on!(machine_name, @db_index, should_input_score_trigger(),   is_waiting_for_score_input(), should_input_score())
    Predefined.on!(machine_name, @db_index, wait_for_next_match_trigger(),  is_waiting_for_score_input(), is_waiting_for_next_match())
    Predefined.on!(machine_name, @db_index, should_input_score_trigger(),   is_waiting_for_next_match(),  should_input_score())

    opts
    |> list_states()
    |> Enum.reject(&(&1 == is_finished()))
    |> Enum.each(fn state ->
      Predefined.on!(machine_name, @db_index, finish_trigger(), state, is_finished())
      Predefined.on!(machine_name, @db_index, lose_trigger(),   state, is_loser())
    end)
  end

  @impl Rule
  def build_dfa_instance(instance_name, opts \\ []) do
    is_team = Keyword.get(opts, :is_team, true)
    machine_name = machine_name(is_team)

    Predefined.initialize!(instance_name, machine_name, @db_index, is_not_started())
  end

  @impl Rule
  def destroy_dfa_instance(instance_name, _opts \\ []), do: Predefined.deinitialize!(instance_name, @db_index)

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
      should_input_score(),
      is_waiting_for_score_input(),
      is_waiting_for_next_match(),
      is_loser(),
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

  @spec should_input_score() :: String.t()
  def should_input_score(), do: "ShouldInputScore"

  @spec is_waiting_for_score_input() :: String.t()
  def is_waiting_for_score_input(), do: "IsWaitingForScoreInput"

  @spec is_waiting_for_next_match() :: String.t()
  def is_waiting_for_next_match(), do: "IsWaitingForNextMatch"

  @spec is_loser() :: String.t()
  def is_loser(), do: "IsLoser"

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

  @spec wait_for_score_input_trigger() :: String.t()
  def wait_for_score_input_trigger(), do: "wait_for_score_input"

  @spec wait_for_next_match_trigger() :: String.t()
  def wait_for_next_match_trigger(), do: "wait_for_next_match"

  @spec should_input_score_trigger() :: String.t()
  def should_input_score_trigger(), do: "should_input_score_trigger"

  @spec lose_trigger() :: String.t()
  def lose_trigger(), do: "lose"

  @spec finish_trigger() :: String.t()
  def finish_trigger(), do: "finish"
  #
  # =========================================================
  # 関数群
  # =========================================================
  #

  @spec create_freeforall_information(map()) :: {:ok, Information.t()} | {:error, Ecto.Changeset.t()}
  def create_freeforall_information(attrs \\ %{}) do
    %Information{}
    |> Information.changeset(attrs)
    |> Repo.insert()
  end

  @spec get_freeforall_information_by_tournament_id(integer()) :: Information.t() | nil
  def get_freeforall_information_by_tournament_id(tournament_id) do
    Information
    |> where([i], i.tournament_id == ^tournament_id)
    |> Repo.one()
  end

  def truncate_excess_members(%Tournament{is_team: true, id: tournament_id}) do
    teams = Tournaments.get_teams_by_tournament_id(tournament_id)

    %Information{round_number: round_number} = __MODULE__.get_freeforall_information_by_tournament_id(tournament_id)


  end
end

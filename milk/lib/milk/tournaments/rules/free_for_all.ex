defmodule Milk.Tournaments.Rules.FreeForAll do
  @moduledoc """
  FreeForAllに関する記述
  """
  import Ecto.Query, warn: false
  import Common.Sperm

  alias Common.Tools
  alias Milk.Tournaments.Rules.FreeForAll.{
    Information,
    Status,
    TeamStatus
  }
  alias Milk.Tournaments.Rules.FreeForAll.Round.{
    Table,
    TeamInformation,
    TeamMatchInformation
  }
  alias Milk.Tournaments.Rules.FreeForAll.Round.Information, as: RoundInformation
  alias Milk.Tournaments.{
    Team,
    Tournament
  }
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

  @doc """
  不要なメンバーを取り除くための関数
  """
  def truncate_excess_members(%Tournament{is_team: true, id: tournament_id}) do
    with information when not is_nil(information) <- __MODULE__.get_freeforall_information_by_tournament_id(tournament_id),
         teams                                    <- get_teams_desc_by_confirmation_date(tournament_id),
         {:ok, remaining_teams_num}               <- get_closest_num_of_multiple(teams, information),
         {:ok, nil}                               <- delete_surplus_teams(teams, remaining_teams_num) do
      {:ok, nil}
    else
      nil             -> {:error, "round information is nil"}
      {:error, error} -> {:error, error}
      _               -> {:error, "error on truncate excess members"}
    end
  end

  def truncate_excess_members(%Tournament{is_team: false, id: tournament_id}) do
    with information when not is_nil(information) <- __MODULE__.get_freeforall_information_by_tournament_id(tournament_id),
         entrants                                 <- Tournaments.get_entrants(tournament_id),
         {:ok, remaining_entrants_num}            <- get_closest_num_of_multiple(entrants, information),
         {:ok, nil}                               <- delete_surplus_entrants(entrants, remaining_entrants_num) do
      {:ok, nil}
    else
      nil             -> {:error, "round information is nil"}
      {:error, error} -> {:error, error}
      _               -> {:error, "error on truncate excess members"}
    end
  end

  defp delete_surplus_teams(teams, remaining_teams_num) when length(teams) > remaining_teams_num do
    teams
    |> Enum.slice(remaining_teams_num..length(teams))
    |> Enum.map(&Repo.delete(&1))
    |> Enum.all?(&match?({:ok, _}, &1))
    |> Tools.boolean_to_tuple()
  end
  #defp delete_surplus_teams(_, _), do: {:error, "invalid remaining teams number"}
  defp delete_surplus_teams(_, _), do: {:ok, nil}

  defp delete_surplus_entrants(entrants, remaining_entrants_num) when length(entrants) > remaining_entrants_num do
    entrants
    |> Enum.slice(remaining_entrants_num..length(entrants))
    |> Enum.map(&Repo.delete(&1))
    |> Enum.all?(&match?({:ok, _}, &1))
    |> Tools.boolean_to_tuple()
  end
  #defp delete_surplus_entrants(_, _), do: {:error, "invalid remaining entrants number"}
  defp delete_surplus_entrants(_, _), do: {:ok, nil}

  defp get_closest_num_of_multiple([], _), do: {:error, "empty list is given on getting closest num of multiple"}
  defp get_closest_num_of_multiple(list, %Information{round_number: round_number}) do
    list
    |> length()
    |> Tools.get_closest_num_of_multiple(round_number)
    ~> remaining_members_num

    {:ok, remaining_members_num}
  end

  @spec get_teams_desc_by_confirmation_date(integer()) :: [Team.t()]
  defp get_teams_desc_by_confirmation_date(tournament_id) do
    Team
    |> where([t], t.tournament_id == ^tournament_id)
    |> order_by([t], desc: :confirmation_date)
    |> order_by([t], asc: fragment("? NULLS LAST", t.confirmation_date))
    |> Repo.all()
  end

  def generate_round_tables(%Tournament{is_team: true, id: tournament_id}, round_index) do
    # 参加人数割るround_capacityの数だけ対戦カードを作る（繰り上げ）
    teams = Tournaments.get_confirmed_teams(tournament_id)
    information = __MODULE__.get_freeforall_information_by_tournament_id(tournament_id)

    tables_num = ceil(length(teams) / information.round_capacity)

    1..tables_num
    |> Enum.to_list()
    |> Enum.map(fn n ->
      __MODULE__.create_round_table(%{name: "テーブル#{n}", round_index: round_index, tournament_id: tournament_id})
    end)
    |> Enum.reduce([], fn {:ok, table}, acc ->
      [table | acc]
    end)
    ~> tables

    assign_teams(teams, tables)

    {:ok, nil}
  end

  def generate_round_tables(%Tournament{is_team: false, id: tournament_id}, round_index) do
    # 参加人数割るround_capacityの数だけ対戦カードを作る（繰り上げ）
    entrants = Tournaments.get_entrants(tournament_id)
    information = __MODULE__.get_freeforall_information_by_tournament_id(tournament_id)

    tables_num = ceil(length(entrants) / information.round_capacity)

    1..tables_num
    |> Enum.to_list()
    |> Enum.map(fn n ->
      __MODULE__.create_round_table(%{name: "テーブル#{n}", round_index: round_index, tournament_id: tournament_id})
    end)
    |> Enum.reduce([], fn {:ok, table}, acc ->
      [table | acc]
    end)
    ~> tables

    assign_entrants(entrants, tables)

    {:ok, nil}
  end

  defp assign_teams(teams, tables) do
    teams
    |> Enum.shuffle()
    |> do_assign_teams(tables)
  end

  defp do_assign_teams(teams, tables, count \\ 0)
  defp do_assign_teams([], _, _), do: {:ok, nil}
  defp do_assign_teams(teams, tables, count) do
    [team | remaining_teams] = teams
    table = Enum.at(tables, rem(count, length(tables)))

    %TeamInformation{}
    |> TeamInformation.changeset(%{table_id: table.id, team_id: team.id})
    |> Repo.insert()

    do_assign_teams(remaining_teams, tables, count + 1)
  end

  defp assign_entrants(entrants, tables) do
    entrants
    |> Enum.shuffle()
    |> do_assign_entrants(tables)
  end

  defp do_assign_entrants(entrants, tables, count \\ 0)
  defp do_assign_entrants([], _, _), do: {:ok, nil}
  defp do_assign_entrants(entrants, tables, count) do
    [entrant | remaining_entrants] = entrants
    table = Enum.at(tables, rem(count, length(tables)))

    %RoundInformation{}
    |> RoundInformation.changeset(%{table_id: table.id, user_id: entrant.user_id})
    |> Repo.insert()

    do_assign_entrants(remaining_entrants, tables, count + 1)
  end

  def initialize_status(%Tournament{is_team: true, id: tournament_id}) do
    tournament_id
    |> Tournaments.get_confirmed_teams()
    |> Enum.map(&__MODULE__.create_team_status(%{team_id: &1.id, tournament_id: tournament_id}))
    |> Enum.all?(&match?({:ok, _}, &1))
    |> Tools.boolean_to_tuple()
  end

  def initialize_status(%Tournament{is_team: false, id: tournament_id}) do
    tournament_id
    |> Tournaments.get_entrants()
    |> Enum.map(&__MODULE__.create_status(%{user_id: &1.user_id, tournament_id: tournament_id}))
    |> Enum.all?(&match?({:ok, _}, &1))
    |> Tools.boolean_to_tuple()
  end

  def create_team_status(attrs \\ %{}) do
    %TeamStatus{}
    |> TeamStatus.changeset(attrs)
    |> Repo.insert()
  end

  def create_status(attrs \\ %{}) do
    %Status{}
    |> Status.changeset(attrs)
    |> Repo.insert()
  end

  def create_round_table(attrs \\ %{}) do
    %Table{}
    |> Table.changeset(attrs)
    |> Repo.insert()
  end

  def load_tables_by_tournament_id(tournament_id) do
    tournament_id
    |> __MODULE__.get_tables_by_tournament_id()
    |> Repo.preload(:information)
  end

  @spec get_tables_by_tournament_id(integer()) :: Table.t() | nil
  def get_tables_by_tournament_id(tournament_id) do
    Table
    |> where([t], t.tournament_id == ^tournament_id)
    |> Repo.all()
  end

  def get_round_information(table_id) do
    RoundInformation
    |> where([t], t.table_id == ^table_id)
    |> Repo.all()
  end

  def get_round_team_information(table_id) do
    TeamInformation
    |> where([t], t.table_id == ^table_id)
    |> Repo.all()
  end

  def get_team_match_information(round_team_information_id) do
    TeamMatchInformation
    |> where([t], t.round_id == ^round_team_information_id)
    |> Repo.all()
  end
end

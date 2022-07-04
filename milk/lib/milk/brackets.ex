defmodule Milk.Brackets do
  use Timex
  use Common.Stats

  import Ecto.Query, warn: false

  alias Common.Tools
  alias Milk.{
    Repo,
    Tournaments
  }
  alias Milk.Brackets.{
    Bracket,
    BracketLog,
    BracketArchive,
    Participant,
    ParticipantLog
  }

  def get_number() do
    beginning_of_month = Timex.now()
      |> Timex.beginning_of_month()

    end_of_month = Timex.now()
      |> Timex.end_of_month()

    bracket_count = Bracket
      |> where([b], ^beginning_of_month < b.create_time and b.create_time < ^end_of_month)
      |> select([t], count(t.id))
      |> Repo.one()

    bracket_log_count = BracketLog
      |> where([b], ^beginning_of_month < b.create_time and b.create_time < ^end_of_month)
      |> select([t], count(t.id))
      |> Repo.one()

    bracket_archive_count = BracketArchive
      |> where([b], ^beginning_of_month < b.create_time and b.create_time < ^end_of_month)
      |> select([t], count(t.id))
      |> Repo.one()

    bracket_count + bracket_log_count + bracket_archive_count
  end

  def get_bracket_including_logs(bracket_id) do
    with nil                         <- __MODULE__.get_bracket(bracket_id),
         %BracketLog{} = bracket_log <- __MODULE__.get_bracket_log_by_bracket_id(bracket_id) do
      bracket_log
      |> Map.put(:id, bracket_log.bracket_id)
      |> Map.put(:is_finished, true)
    else
      %Bracket{} = bracket -> bracket
      _                    -> nil
    end
  end

  def get_bracket(bracket_id) do
    Bracket
    |> where([b], b.id == ^bracket_id)
    |> Repo.one()
  end

  def get_bracket_log_by_bracket_id(bracket_id) do
    BracketLog
    |> where([b], b.bracket_id == ^bracket_id)
    |> Repo.one()
  end

  def get_bracket_including_logs_by_url(url) do
    with nil                         <- __MODULE__.get_bracket_by_url(url),
         %BracketLog{} = bracket_log <- __MODULE__.get_bracket_log_by_url(url) do
      bracket_log
      |> Map.put(:id, bracket_log.bracket_id)
      |> Map.put(:is_finished, true)
    else
      %Bracket{} = bracket -> bracket
      _                    -> nil
    end
  end

  def get_bracket_by_url(url) do
    Bracket
    |> where([b], b.url == ^url)
    |> Repo.one()
  end

  def get_bracket_log_by_url(url) do
    BracketLog
    |> where([b], b.url == ^url)
    |> Repo.one()
  end

  def get_brackets_by_owner_id(owner_id) do
    Bracket
    |> where([b], b.owner_id == ^owner_id)
    |> Repo.all()
  end

  def get_bracket_logs_by_owner_id(owner_id) do
    BracketLog
    |> where([b], b.owner_id == ^owner_id)
    |> Repo.all()
  end

  def create_bracket(attrs \\ %{}) do
    %Bracket{}
    |> Bracket.changeset(attrs)
    |> Repo.insert()
  end

  def create_bracket_log(attrs \\ %{}) do
    %BracketLog{}
    |> BracketLog.changeset(attrs)
    |> Repo.insert()
  end

  def update_bracket(%Bracket{} = bracket, attrs) do
    bracket
    |> Bracket.changeset(attrs)
    |> Repo.update()
  end

  @spec is_url_duplicated?(String.t()) :: boolean()
  def is_url_duplicated?(url) do
    with false <- is_url_duplicated_in_brackets?(url) do
      is_url_duplicated_in_bracket_logs?(url)
    else
      true -> true
    end
  end

  defp is_url_duplicated_in_brackets?(url) do
    Bracket
    |> where([b], b.url == ^url)
    |> Repo.exists?()
  end

  defp is_url_duplicated_in_bracket_logs?(url) do
    BracketLog
    |> where([b], b.url == ^url)
    |> Repo.exists?()
  end

  def create_participant(attrs \\ %{}) do
    %Participant{}
    |> Participant.changeset(attrs)
    |> Repo.insert()
  end

  def create_participant_log(attrs \\ %{}) do
    %ParticipantLog{}
    |> ParticipantLog.changeset(attrs)
    |> Repo.insert()
  end

  def create_bracket_archive(attrs \\ %{}) do
    %BracketArchive{}
    |> BracketArchive.changeset(attrs)
    |> Repo.insert()
  end

  def create_participants(names, bracket_id) do
    names
    |> Enum.map(&__MODULE__.create_participant(%{name: &1, bracket_id: bracket_id}))
    |> Tools.reduce_ok_list("error on create participants")
  end

  def initialize_brackets(bracket_id, deleted_participant_id_list \\ []) do
    bracket = __MODULE__.get_bracket(bracket_id)

    if is_nil(bracket.match_list_str) do
      bracket_id
      |> __MODULE__.get_participants()
      |> Enum.map(&(&1.id))
    else
      match_list_id_list = bracket.match_list_str
        |> Code.eval_string()
        |> elem(0)
        |> List.flatten()
        |> Enum.reject(&(&1 in deleted_participant_id_list))

      participant_id_list = bracket_id
        |> __MODULE__.get_participants()
        |> Enum.map(&(&1.id))

      Enum.uniq(match_list_id_list ++ participant_id_list)
    end
    |> do_generate_match_list(bracket_id)
  end

  defp do_generate_match_list(participant_id_list, bracket_id) do
    {:ok, match_list} = Tournaments.generate_matchlist_without_shuffle(participant_id_list)

    match_list_with_fight_result = Tournamex.initialize_match_list_with_fight_result(match_list)

    match_list_with_fight_result = match_list_with_fight_result
      |> List.flatten()
      |> Enum.reduce(match_list_with_fight_result, fn x, acc ->
        participant_id = x["user_id"]
        participant = __MODULE__.get_participant(participant_id)

        acc
        |> Tournaments.put_value_on_brackets(participant_id, %{"id" => participant_id})
        |> Tournaments.put_value_on_brackets(participant_id, %{"name" => participant.name})
        |> Tournaments.put_value_on_brackets(participant_id, %{"win_count" => 0})
        |> Tournaments.put_value_on_brackets(participant_id, %{"icon_path" => nil})
        |> Tournaments.put_value_on_brackets(participant_id, %{"round" => 0})
      end)

    bracket_id
    |> __MODULE__.get_bracket()
    |> __MODULE__.update_bracket(%{match_list_str: inspect(match_list), match_list_with_fight_result_str: inspect(match_list_with_fight_result)})
  end

  def get_participants_including_log(bracket_id) do
    with bracket when is_nil(bracket)             <- __MODULE__.get_bracket(bracket_id),
         bracket_log when not is_nil(bracket_log) <- __MODULE__.get_bracket_log_by_bracket_id(bracket_id) do
      __MODULE__.get_participant_logs(bracket_log.id)
    else
      %Bracket{id: bracket_id} -> __MODULE__.get_participants(bracket_id)
      _                        -> []
    end
  end

  def get_participants(bracket_id) do
    Participant
    |> where([p], p.bracket_id == ^bracket_id)
    |> Repo.all()
  end

  def get_participant_logs(bracket_id) do
    ParticipantLog
    |> where([p], p.bracket_id == ^bracket_id)
    |> Repo.all()
  end

  def get_participant(participant_id) do
    Participant
    |> where([p], p.id == ^participant_id)
    |> Repo.one()
  end

  def edit_brackets(participant_id_list, bracket_id) do
    bracket = __MODULE__.get_bracket(bracket_id)

    match_list = participant_id_list
      |> Tournaments.generate_matchlist_without_shuffle()
      |> elem(1)

    match_list_with_fight_result = Tournamex.initialize_match_list_with_fight_result(match_list)

    match_list_with_fight_result =  match_list_with_fight_result
      |> List.flatten()
      |> Enum.reduce(match_list_with_fight_result, fn x, acc ->
        participant_id = x["user_id"]
        participant = __MODULE__.get_participant(participant_id)

        acc
        |> Tournaments.put_value_on_brackets(participant_id, %{"id" => participant_id})
        |> Tournaments.put_value_on_brackets(participant_id, %{"name" => participant.name})
        |> Tournaments.put_value_on_brackets(participant_id, %{"win_count" => 0})
        |> Tournaments.put_value_on_brackets(participant_id, %{"icon_path" => nil})
        |> Tournaments.put_value_on_brackets(participant_id, %{"round" => 0})
      end)

    __MODULE__.update_bracket(bracket, %{match_list_str: inspect(match_list), match_list_with_fight_result_str: inspect(match_list_with_fight_result)})
  end

  def start(bracket_id) do
    bracket = __MODULE__.get_bracket(bracket_id)

    if bracket.is_started do
      {:error, "Already started"}
    else
      __MODULE__.update_bracket(bracket, %{is_started: true})
    end
  end

  def undo_start(bracket_id) do
    bracket = __MODULE__.get_bracket(bracket_id)

    if bracket.is_started do
      __MODULE__.update_bracket(bracket, %{is_started: false})
    else
      {:error, "Is not started"}
    end
  end

  def defeat_loser_participant(winner_participant_id, loser_participant_id, bracket_id) do
    # NOTE: last_match_listの保存
    bracket = __MODULE__.get_bracket(bracket_id)

    __MODULE__.update_bracket(bracket, %{last_match_list_str: bracket.match_list_str, last_match_list_with_fight_result_str: bracket.match_list_with_fight_result_str})

    match_list = bracket.match_list_str
      |> Code.eval_string()
      |> elem(0)
      |> Tournamex.delete_loser(loser_participant_id)

    match_list_with_fight_result = bracket.match_list_with_fight_result_str
      |> Code.eval_string()
      |> elem(0)
      |> Tournamex.win_count_increment(winner_participant_id)

      __MODULE__.update_bracket(bracket, %{match_list_str: inspect(match_list), match_list_with_fight_result_str: inspect(match_list_with_fight_result)})
  end

  def archive_and_delete(bracket) do
    bracket
    |> Map.from_struct()
    |> __MODULE__.create_bracket_archive()

    __MODULE__.delete(bracket)
  end

  def delete(bracket), do: Repo.delete(bracket)

  def delete_participant(participant), do: Repo.delete(participant)

  def undo_progress(bracket) do
    if is_nil(bracket.last_match_list_str) do
      {:error, "Unable to undo anymore"}
    else
      attrs = %{
        match_list_str: bracket.last_match_list_str,
        match_list_with_fight_result_str: bracket.last_match_list_with_fight_result_str,
        last_match_list_str: nil,
        last_match_list_with_fight_result_str: nil
      }

      __MODULE__.update_bracket(bracket, attrs)
    end
  end

  def disable_to_undo_start(bracket), do: __MODULE__.update_bracket(bracket, %{unable_to_undo_start: true})

  def finish(bracket_id) do
    with bracket when not is_nil(bracket) <- __MODULE__.get_bracket(bracket_id),
         {:ok, log}                       <- create_bracket_log_on_finish(bracket),
         {:ok, _}                         <- create_participant_logs_on_finish(bracket, log.id) do
      __MODULE__.delete(bracket)
    else
      nil             -> {:error, "Bracket is nil"}
      {:error, error} -> {:error, error}
    end
  end

  defp create_bracket_log_on_finish(bracket) do
    bracket
    |> Map.from_struct()
    |> Map.put(:bracket_id, bracket.id)
    |> __MODULE__.create_bracket_log()
  end

  defp create_participant_logs_on_finish(bracket, bracket_log_id) do
    bracket.id
    |> __MODULE__.get_participants()
    |> Enum.map(fn participant ->
      participant
      |> Map.from_struct()
      |> Map.put(:participant_id, participant.id)
      |> Map.put(:bracket_id, bracket_log_id)
      |> __MODULE__.create_participant_log()
    end)
    |> Enum.all?(&match?({:ok, _}, &1))
    |> Tools.boolean_to_tuple()
  end

    @doc """
  Lists all brackets.
  """
  @spec list_bracket() :: [Bracket.t()]
  def list_bracket(), do: Repo.all(Bracket)
  def collect_bracket do
    list_bracket()
    |> Enum.map(fn t -> t.create_time.year * 10000 + t.create_time.month * 100 + t.create_time.day end)
    |> create_statistics()
  end

    @doc """
  Lists all brackets_log.
  """
  @spec list_bracket_log() :: [BracketLog.b()]
  def list_bracket_log(), do: Repo.all(BracketLog)
  def collect_bracket_log do
    list_bracket_log()
    |> Enum.map(fn t -> t.create_time.year * 10000 + t.create_time.month * 100 + t.create_time.day end)
    |> create_statistics()
  end

      @doc """
  Lists all brackets_archive.
  """
  @spec list_bracket_archive() :: [BracketArchive.b()]
  def list_bracket_archive(), do: Repo.all(BracketArchive)
  def collect_bracket_archive do
    list_bracket_archive()
    |> Enum.map(fn t -> t.create_time.year * 10000 + t.create_time.month * 100 + t.create_time.day end)
    |> create_statistics()
  end
end

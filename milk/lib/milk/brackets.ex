defmodule Milk.Brackets do
  import Ecto.Query, warn: false

  alias Common.Tools
  alias Milk.{
    Repo,
    Tournaments
  }
  alias Milk.Brackets.{
    Bracket,
    BracketLog,
    Participant
  }

  def get_bracket(bracket_id) do
    Bracket
    |> where([b], b.id == ^bracket_id)
    |> Repo.one()
  end

  def get_brackets_by_owner_id(owner_id) do
    Bracket
    |> where([b], b.owner_id == ^owner_id)
    |> Repo.all()
  end

  def create_bracket(attrs \\ %{}) do
    %Bracket{}
    |> Bracket.changeset(attrs)
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

  def create_participants(names, bracket_id) do
    names
    |> Enum.map(&__MODULE__.create_participant(%{name: &1, bracket_id: bracket_id}))
    |> Tools.reduce_ok_list("error on create participants")
  end

  def initialize_brackets(bracket_id) do
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
        |> Tournaments.put_value_on_brackets(participant_id, %{"name" => participant.name})
        |> Tournaments.put_value_on_brackets(participant_id, %{"win_count" => 0})
        |> Tournaments.put_value_on_brackets(participant_id, %{"icon_path" => nil})
        |> Tournaments.put_value_on_brackets(participant_id, %{"round" => 0})
      end)

    bracket_id
    |> __MODULE__.get_bracket()
    |> __MODULE__.update_bracket(%{match_list_str: inspect(match_list), match_list_with_fight_result_str: inspect(match_list_with_fight_result)})
  end

  def get_participants(bracket_id) do
    Participant
    |> where([p], p.bracket_id == ^bracket_id)
    |> Repo.all()
  end

  def get_participant(participant_id) do
    Participant
    |> where([p], p.id == ^participant_id)
    |> Repo.one()
  end
end

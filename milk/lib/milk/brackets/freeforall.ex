defmodule Milk.Brackets.FreeForAll do
  import Ecto.Query, warn: false

  alias Milk.Repo
  alias Milk.Brackets
  alias Milk.Brackets.Bracket
  alias Milk.Brackets.FreeForAll.Information
  alias Milk.Brackets.FreeForAll.Round.Table
  alias Milk.Brackets.FreeForAll.Round.Information, as: RoundInformation

  def create_freeforall_information(attrs \\ %{}) do
    %Information{}
    |> Information.changeset(attrs)
    |> Repo.insert()
  end

  def get_freeforall_information_by_bracket_id(bracket_id) do
    Information
    |> where([i], i.bracket_id == ^bracket_id)
    |> Repo.one()
  end

  def create_round_table(attrs \\ %{}) do
    %Table{}
    |> Table.changeset(attrs)
    |> Repo.insert()
  end

  def initialize_round_tables(%Bracket{id: bracket_id}, round_index) do
    participants = Brackets.get_participants(bracket_id)
    information = __MODULE__.get_freeforall_information_by_bracket_id(bracket_id)

    table_num = ceil(length(participants) / information.round_capacity)

    tables = 1..table_num
      |> Enum.to_list()
      |> Enum.map(&__MODULE__.create_round_table(%{name: "Table#{&1}", round_index: round_index, bracket_id: bracket_id}))
      |> Enum.reduce([], fn {:ok, table}, acc ->
        [table | acc]
      end)

    assign_participants(participants, tables)
  end

  defp assign_participants(participants, tables) do
    participants
    #|> Enum.shuffle()
    |> do_assign_participants(tables)
  end

  defp do_assign_participants(participants, tables, count \\ 0)
  defp do_assign_participants([], _, _), do: {:ok, nil}
  defp do_assign_participants(participants, tables, count) do
    [participant | remaining_participants] = participants
    table = Enum.at(participants, rem(count, length(tables)))

    %RoundInformation{}
    |> RoundInformation.changeset(%{table_id: table.id, participant_id: participant.id})
    |> Repo.insert()

    do_assign_participants(remaining_participants, tables, count + 1)
  end
end

defmodule Milk.Tournaments.Entries do
  @moduledoc """
  エントリー情報のCRUDに関するモジュール
  """
  import Ecto.Query, warn: false
  import Common.Sperm

  alias Common.Tools
  alias Milk.Repo
  alias Milk.Tournaments.Entry
  alias Milk.Tournaments.Entries.Information, as: EntryInformation
  alias Milk.Tournaments.Entries.Template, as: EntryTemplate

  @spec create_entry_template(map()) :: {:ok, EntryTemplate.t()} | {:error, Ecto.Changeset.t()}
  def create_entry_template(entry_template_information) do
    %EntryTemplate{}
    |> EntryTemplate.changeset(entry_template_information)
    |> Repo.insert()
  end

  @spec create_entry_templates([map()]) :: {:ok, nil} | {:error, nil}
  def create_entry_templates(entry_templates) when is_list(entry_templates) do
    entry_templates
    |> Enum.map(&__MODULE__.create_entry_template(&1))
    |> Enum.all?(&match?({:ok, _}, &1))
    |> Tools.boolean_to_tuple()
  end

  @spec create_entry([map()], integer()) :: {:ok, nil} | {:error, String.t()}
  def create_entry(entry_information_list, tournament_id) do
    %Entry{}
    |> Entry.changeset(%{tournament_id: tournament_id})
    |> Repo.insert()
    ~> {:ok, entry}

    entry_information_list
    |> Enum.map(fn entry_information ->
      entry_information = Map.put(entry_information, :entry_id, entry.id)

      %EntryInformation{}
      |> EntryInformation.changeset(entry_information)
      |> Repo.insert()
    end)
    |> Enum.all?(&match?({:ok, _}, &1))
    |> Tools.boolean_to_tuple()
  end

  @spec get_entries(integer()) :: [Entry.t()]
  def get_entries(tournament_id) do
    Entry
    |> where([e], e.tournament_id == ^tournament_id)
    |> Repo.all()
  end

  @spec get_entry_information(integer()) :: [EntryInformation.t()]
  def get_entry_information(entry_id) do
    EntryInformation
    |> where([ei], ei.entry_id == ^entry_id)
    |> Repo.all()
  end
end

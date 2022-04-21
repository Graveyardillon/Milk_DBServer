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

  @spec create_entry([map()], integer(), integer()) :: {:ok, nil} | {:error, String.t()}
  def create_entry(entry_information_list, tournament_id, user_id) do
    %Entry{}
    |> Entry.changeset(%{tournament_id: tournament_id, user_id: user_id})
    |> Repo.insert()
    ~> {:ok, entry}

    entry_information_list
    |> Enum.map(fn entry_information ->
      entry_information = Map.put(entry_information, "entry_id", entry.id)

      %EntryInformation{}
      |> EntryInformation.changeset(entry_information)
      |> Repo.insert()
    end)
    |> Enum.all?(&match?({:ok, _}, &1))
    |> Tools.boolean_to_tuple()
  end

  def get_entry_template(tournament_id) do
    EntryTemplate
    |> where([et], et.tournament_id == ^tournament_id)
    |> Repo.all()
  end

  @spec get_entries(integer()) :: [Entry.t()]
  def get_entries(tournament_id) do
    Entry
    |> where([e], e.tournament_id == ^tournament_id)
    |> Repo.all()
  end

  def get_entries_by_user_id(user_id) do
    Entry
    |> where([e], e.user_id == ^user_id)
    |> Repo.all()
  end

  @spec delete_entries_by_user_id(integer()) :: {:ok, nil} | {:error, String.t()}
  def delete_entries_by_user_id(nil), do: {:ok, nil}
  def delete_entries_by_user_id(user_id) do
    user_id
    |> __MODULE__.get_entries_by_user_id()
    |> Enum.map(&Repo.delete(&1))
    |> Enum.all?(&match?({:ok, _}, &1))
    |> Tools.boolean_to_tuple()
  end

  @spec get_entry_information_by_user_id(integer()) :: [EntryInformation.t()]
  def get_entry_information_by_user_id(user_id) do
    EntryInformation
    |> join(:inner, [ei], e in Entry, on: e.id == ei.entry_id)
    |> where([ei, e], e.user_id == ^user_id)
    |> Repo.all()
  end

  @spec has_entry_info?(integer()) :: boolean()
  def has_entry_info?(tournament_id) do
    EntryTemplate
    |> where([et], et.tournament_id == ^tournament_id)
    |> Repo.exists?()
  end

  @spec delete_entry_information_by_user_id(integer()) :: {:ok, nil} | {:error, nil}
  def delete_entry_information_by_user_id(user_id) do
    user_id
    |> __MODULE__.get_entry_information_by_user_id()
    |> Enum.map(&Repo.delete(&1))
    |> Enum.all?(&match?({:ok, _}, &1))
    |> Tools.boolean_to_tuple()
  end
end

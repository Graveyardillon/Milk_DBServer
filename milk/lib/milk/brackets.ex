defmodule Milk.Brackets do
  import Ecto.Query, warn: false

  alias Common.Tools
  alias Milk.{
    Repo
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
end

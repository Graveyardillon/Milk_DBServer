defmodule Milk.Brackets do
  import Ecto.Query, warn: false

  alias Milk.{
    Repo
  }
  alias Milk.Brackets.{
    Bracket,
    BracketLog
  }

  def get_bracket(bracket_id) do
    Bracket
    |> where([b], b.id == ^bracket_id)
    |> Repo.one()
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
end

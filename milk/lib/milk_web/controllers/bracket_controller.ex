defmodule MilkWeb.BracketController do
  @moduledoc """
  Bracket Controller
  """
  use MilkWeb, :controller

  alias Milk.Brackets
  alias Common.Tools

  # TODO: メンバー追加
  def create_bracket(conn, %{"brackets" => %{"name" => name, "owner_id" => owner_id, "rule" => rule, "url" => url, "enabled_bronze_medal_match" => enabled_bronze_medal_match}}) do
    with false          <- Brackets.is_url_duplicated?(url),
         {:ok, bracket} <- Brackets.create_bracket(%{name: name, owner_id: owner_id, url: url, rule: rule, enabled_bronze_medal_match: enabled_bronze_medal_match}) do
      render(conn, "show.json", bracket: bracket)
    else
      true            -> json(conn, %{result: false, error: "Urls is duplicated"})
      {:error, error} -> render(conn, "error.json", %{error: error.errors})
    end
  end
  def create_bracket(conn, %{"brackets" => %{"name" => name, "owner_id" => owner_id, "rule" => rule, "url" => url}}) do
    __MODULE__.create_bracket(conn, %{"brackets" => %{"name" => name, "owner_id" => owner_id, "rule" => rule, "url" => url, "enabled_bronze_medal_match" => false}})
  end

  # TODO: SQLインジェクションの確認
  def is_url_valid(conn, %{"url" => url}), do: json(conn, %{result: !Brackets.is_url_duplicated?(url)})

  def get_bracket(conn, %{"bracket_id" => bracket_id}) do
    bracket = Brackets.get_bracket(bracket_id)

    if is_nil(bracket) do
      render(conn, "error.json", error: "bracket is nil")
    else
      render(conn, "show.json", bracket: bracket)
    end
  end

  def get_brackets_by_owner_id(conn, %{"owner_id" => owner_id}) do
    brackets = owner_id
      |> Tools.to_integer_as_needed()
      |> Brackets.get_brackets_by_owner_id()

    render(conn, "index.json", brackets: brackets)
  end

  def create_participants(conn, %{"names" => names, "bracket_id" => bracket_id}) do
    with {:ok, _} <- Brackets.create_participants(names, bracket_id),
         {:ok, _} <- Brackets.initialize_brackets(bracket_id) do
      json(conn, %{result: true})
    else
      _ -> json(conn, %{result: false})
    end
  end

  def get_participants(conn, %{"bracket_id" => bracket_id}) do
    participants = bracket_id
      |> Tools.to_integer_as_needed()
      |> Brackets.get_participants()

    render(conn, "index.json", participants: participants)
  end
end

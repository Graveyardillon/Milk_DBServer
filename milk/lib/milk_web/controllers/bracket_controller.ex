defmodule MilkWeb.BracketController do
  @moduledoc """
  Bracket Controller
  """
  use MilkWeb, :controller

  alias Milk.Brackets

  # TODO: メンバー追加
  def create_bracket(conn, %{"brackets" => %{"name" => name, "owner_id" => owner_id, "url" => url, "enabled_bronze_medal_match" => enabled_bronze_medal_match}}) do
    with false          <- Brackets.is_url_duplicated?(url),
         {:ok, bracket} <- Brackets.create_bracket(%{name: name, owner_id: owner_id, url: url, enabled_bronze_medal_match: enabled_bronze_medal_match}) do
      render(conn, "show.json", bracket: bracket)
    else
      true            -> json(conn, %{result: false, error: "Urls is duplicated"})
      {:error, error} -> render(conn, "error.json", %{error: error.errors})
    end
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
end

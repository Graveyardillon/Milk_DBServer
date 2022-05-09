defmodule MilkWeb.BracketController do
  @moduledoc """
  Bracket Controller
  """
  use MilkWeb, :controller

  alias Milk.Brackets

  def create_bracket(conn, %{"brackets" => %{"name" => name, "owner_id" => owner_id, "url" => url, "enabled_bronze_medal_match" => enabled_bronze_medal_match}}) do
    with false          <- Brackets.is_url_duplicated?(url),
         {:ok, bracket} <- Brackets.create_bracket(%{name: name, owner_id: owner_id, url: url, enabled_bronze_medal_match: enabled_bronze_medal_match}) do
      render(conn, "show.json", bracket: bracket)
    else
      true            -> json(conn, %{result: false, error: "Urls is duplicated"})
      {:error, error} -> render(conn, "error.json", %{error: error.errors})
    end
  end

  def is_url_valid(conn, %{"url" => url}), do: json(conn, %{result: !Brackets.is_url_duplicated?(url)})

  # TODO: bracket取得用の関数

end

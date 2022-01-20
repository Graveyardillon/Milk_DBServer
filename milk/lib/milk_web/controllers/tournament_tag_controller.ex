defmodule MilkWeb.TournamentTagController do

  use MilkWeb, :controller


  alias Milk.{
    Tournaments,
    TournamentTag
  }

  def create(conn, %{"tag_name" => tag_name}) do
    TournamentTag.create_tag(tag_name)
    |> case do
      {:ok, result} -> json(conn, %{result: true})
      {:error, _} -> json(conn, %{result: false})
    end
  end

  def delete(conn, %{"tag_id" => tag_id}) do
    case TournamentTag.delete_tag(tag_id) do
      {:ok, result} -> json(conn, %{result: true})
      {:error, error} -> json(conn, %{result: false})
    end
  end

  def list(conn, _params) do
    tags = TournamentTag.list()
    render(conn, "list.json", tags: tags)
  end

  def set_tags(conn, %{"tournament_id" => id, "tag_ids" => tag_ids}) do
    case Tournaments.get_tournament(id) do
      nil ->
        json(conn, %{result: false, error: "tournament not found"})
      tournament ->
        case TournamentTag.update_relation(tournament, tag_ids) do
          {:ok, result} -> json(conn, %{result: true})
          {:error, error} -> json(conn, %{result: false})
        end
    end

  end
end

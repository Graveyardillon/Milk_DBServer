defmodule MilkWeb.EntrantController do
  use MilkWeb, :controller

  alias Milk.Tournaments
  alias Milk.Tournaments.Entrant

  # action_fallback MilkWeb.FallbackController

  def index(conn, _params) do
    entrant = Tournaments.list_entrant()
    render(conn, "index.json", entrant: entrant)
  end

  def create(conn, %{"entrant" => entrant_params}) do
    with {:ok, %Entrant{} = entrant} <- Tournaments.create_entrant(entrant_params) do
      conn
      # |> put_status(:created)
      # |> put_resp_header("location", Routes.entrant_path(conn, :show, entrant))
      |> render("show.json", entrant: entrant)
    end
  end

  def show(conn, %{"id" => id}) do
    entrant = Tournaments.get_entrant!(id)
    render(conn, "show.json", entrant: entrant)
  end

  def update(conn, %{"id" => id, "entrant" => entrant_params}) do
    entrant = Tournaments.get_entrant!(id)

    with {:ok, %Entrant{} = entrant} <- Tournaments.update_entrant(entrant, entrant_params) do
      render(conn, "show.json", entrant: entrant)
    end
  end

  def delete(conn, %{"id" => id}) do
    entrant = Tournaments.get_entrant!(id)

    with {:ok, %Entrant{}} <- Tournaments.delete_entrant(entrant) do
      send_resp(conn, :no_content, "")
    end
  end
end

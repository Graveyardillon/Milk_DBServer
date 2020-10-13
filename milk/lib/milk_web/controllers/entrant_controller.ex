defmodule MilkWeb.EntrantController do
  use MilkWeb, :controller

  alias Milk.Tournaments
  alias Milk.Tournaments.Entrant
  alias Milk.Chat.ChatMember

  # action_fallback MilkWeb.FallbackController

  def index(conn, _params) do
    entrant = Tournaments.list_entrant()
    if entrant do
      render(conn, "index.json", entrant: entrant)
    else
      render(conn, "error.json", error: nil)
    end
  end

  def create(conn, %{"entrant" => entrant_params}) do
    case Tournaments.create_entrant(entrant_params) do
      {:ok, %Entrant{} = entrant} ->
        conn
        # |> put_status(:created)
        # |> put_resp_header("location", Routes.entrant_path(conn, :show, entrant))
        |> render("show.json", entrant: entrant)
      {:error, error} ->
        render(conn, "error.json", error: error)
      {:multierror, error} ->
        render(conn, "multierror.json", error: error)
      _ ->
        render(conn, "error.json", error: nil)
    end
  end

  def show(conn, %{"id" => id}) do
    entrant = Tournaments.get_entrant!(id)
    if (entrant) do
      render(conn, "show.json", entrant: entrant)
    else
      render(conn, "error.json", error: nil)
    end
  end

  def update(conn, %{"id" => id, "entrant" => entrant_params}) do
    entrant = Tournaments.get_entrant!(id)
    if (entrant) do
    case Tournaments.update_entrant(entrant, entrant_params) do
      {:ok, %Entrant{} = entrant} ->
        render(conn, "show.json", entrant: entrant)
      {:error, error} ->
        render(conn, "error.json", error: error)
      _ ->
        render(conn, "error.json", error: nil)
      end
    else
      render(conn, "error.json", error: nil)
    end
  end

  def delete(conn, %{"id" => id}) do
    entrant = Tournaments.get_entrant!(id)

    with {:ok, %Entrant{}} <- Tournaments.delete_entrant(entrant) do
      send_resp(conn, :no_content, "")
    end
  end
end

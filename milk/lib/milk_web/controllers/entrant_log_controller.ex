defmodule MilkWeb.EntrantLogController do
  use MilkWeb, :controller

  alias Milk.Log
  alias Milk.Log.EntrantLog

  action_fallback MilkWeb.FallbackController

  def index(conn, _params) do
    entrant_log = Log.list_entrant_log()
    render(conn, "index.json", entrant_log: entrant_log)
  end

  def create(conn, %{"data" => entrant_log_params}) do
    with {:ok, %EntrantLog{} = entrant_log} <- Log.create_entrant_log(entrant_log_params) do
      conn
      # |> put_status(:created)
      # |> put_resp_header("location", Routes.entrant_log_path(conn, :show, entrant_log))
      |> render("show.json", entrant_log: entrant_log)
    end
  end

  def show(conn, %{"id" => id}) do
    entrant_log = Log.get_entrant_log!(id)
    render(conn, "show.json", entrant_log: entrant_log)
  end

  def update(conn, %{"id" => id, "entrant_log" => entrant_log_params}) do
    entrant_log = Log.get_entrant_log!(id)

    with {:ok, %EntrantLog{} = entrant_log} <- Log.update_entrant_log(entrant_log, entrant_log_params) do
      render(conn, "show.json", entrant_log: entrant_log)
    end
  end

  def delete(conn, %{"id" => id}) do
    entrant_log = Log.get_entrant_log!(id)

    with {:ok, %EntrantLog{}} <- Log.delete_entrant_log(entrant_log) do
      send_resp(conn, :no_content, "")
    end
  end
end

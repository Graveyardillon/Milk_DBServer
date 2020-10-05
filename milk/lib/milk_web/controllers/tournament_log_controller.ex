defmodule MilkWeb.TournamentLogController do
  use MilkWeb, :controller

  alias Milk.Log
  alias Milk.Log.TournamentLog

  action_fallback MilkWeb.FallbackController

  def index(conn, _params) do
    tournament_log = Log.list_tournament_log()
    render(conn, "index.json", tournament_log: tournament_log)
  end

  def create(conn, %{"data" => tournament_log_params}) do
  IO.inspect(tournament_log_params, label: :log)
    with {:ok, %TournamentLog{} = tournament_log} <- Log.create_tournament_log(tournament_log_params) do
      conn
      |> render("show.json", tournament_log: tournament_log)
    end
  end

  def show(conn, %{"id" => id}) do
    tournament_log = Log.get_tournament_log!(id)
    render(conn, "show.json", tournament_log: tournament_log)
  end

  def update(conn, %{"id" => id, "tournament_log" => tournament_log_params}) do
    tournament_log = Log.get_tournament_log!(id)

    with {:ok, %TournamentLog{} = tournament_log} <- Log.update_tournament_log(tournament_log, tournament_log_params) do
      render(conn, "show.json", tournament_log: tournament_log)
    end
  end

  def delete(conn, %{"id" => id}) do
    tournament_log = Log.get_tournament_log!(id)

    with {:ok, %TournamentLog{}} <- Log.delete_tournament_log(tournament_log) do
      send_resp(conn, :no_content, "")
    end
  end
end

defmodule MilkWeb.TournamentController do
  use MilkWeb, :controller

  alias Milk.Tournaments
  alias Milk.Tournaments.Tournament

  # action_fallback MilkWeb.FallbackController

  def index(conn, _params) do
    tournament = Tournaments.list_tournament()
    if(tournament) do
      render(conn, "index.json", tournament: tournament)
    else
      render(conn, "error.json", error: nil)
    end
  end

  def get_game(conn, %{"tournament" => params}) do
    tournament = Tournaments.game_tournament(params)
    if(tournament) do
      render(conn, "index.json", tournament: tournament)
    else
      render(conn, "error.json", error: nil)
    end
  end

  def create(conn, %{"tournament" => tournament_params}) do
    IO.inspect(tournament_params)
    b64 = tournament_params["thumbnail_path"]
    IO.inspect(b64)
    if b64 != "" do
      IO.puts("isn't nil")
      uuid = SecureRandom.uuid()
      File.write!(".static/image/tournament_thumbnail/#{uuid}.png", Base.decode64!(b64))
    end


    case Tournaments.create_tournament(tournament_params) do
    {:ok, %Tournament{} = tournament} ->
      conn
      # |> put_status(:created)
      # |> put_resp_header("location", Routes.tournament_path(conn, :show, tournament))
      |> render("show.json", tournament: tournament)
    {:error, error} ->
      render(conn, "error.json", error: error)
    _ ->
      render(conn, "error.json", error: nil)
    end
  end

  def show(conn, %{"id" => id}) do
    tournament = Tournaments.get_tournament!(id)
    if(tournament) do
      render(conn, "show.json", tournament: tournament)
    else
      render(conn, "error.json", error: nil)
    end
  end

  def update(conn, %{"id" => id, "tournament" => tournament_params}) do
    tournament = Tournaments.get_tournament!(id)
    if(tournament) do
      case Tournaments.update_tournament(tournament, tournament_params) do
        {:ok, %Tournament{} = tournament} ->
          render(conn, "show.json", tournament: tournament)
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
    with {:ok, %Tournament{}} <- Tournaments.delete_tournament(id) do
      send_resp(conn, :no_content, "")
    end
  end

  def participating_tournaments(conn, %{"user_id" => user_id}) do
    tournaments = Tournaments.get_participating_tournaments!(user_id)

    if tournaments do
      render(conn, "index.json", tournament: tournaments)
    else
      render(conn, "error.json", error: nil)
    end
  end

  def tournament_tabs(conn, %{"tournament_id" => tournament_id}) do
    tabs = Tournaments.get_tabs_by_tournament_id(tournament_id)
           |> IO.inspect()

    # TODO: tournament_topics.jsonのrenderを直接呼び出すのではなくshow.jsonからrender_manyをする方がよさそう
    render(conn, "tournament_topics.json", topics: tabs)
  end
end

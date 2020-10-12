defmodule MilkWeb.TournamentController do
  use MilkWeb, :controller

  alias Milk.Ets
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

  def get_tournament_by_master_id(conn, %{"user_id" => user_id}) do
    tournaments = Tournaments.get_tournament_by_master_id(user_id)
    render(conn, "index.json", tournament: tournaments)
  end

  def get_game(conn, %{"tournament" => params}) do
    tournament = Tournaments.game_tournament(params)
    if(tournament) do
      render(conn, "index.json", tournament: tournament)
    else
      render(conn, "error.json", error: nil)
    end
  end

  def create(conn, %{"tournament" => tournament_params, "image" => image}) do
    IO.inspect(image)
    thumbnail_path = if image != "" do
      uuid = SecureRandom.uuid()
      File.cp(image.path, "./static/image/tournament_thumbnail/#{uuid}.jpg")
      uuid
    else
      nil
    end

    case Tournaments.create_tournament(tournament_params, thumbnail_path) do
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

  def show(conn, %{"tournament_id" => id}) do
    tournament = Tournaments.get_tournament!(id)
    if(tournament) do
      render(conn, "show.json", tournament: tournament)
    else
      render(conn, "error.json", error: nil)
    end
  end

  def update(conn, %{"tournament_id" => id, "tournament" => tournament_params}) do
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

  def delete(conn, %{"tournament_id" => id}) do
    with {:ok, %Tournament{}} <- Tournaments.delete_tournament(id) do
      send_resp(conn, :no_content, "")
    end
  end

  def image(conn, %{"filename" => filename}) do
    path = "./static/image/tournament_thumbnail/#{filename}.jpg"

    conn
    |> put_resp_content_type("image/jpeg")
    |> send_file(200, path)
  end

  # Gets tournament info list for home screen.
  def home(conn, _params) do
    tournaments = Tournaments.home_tournament()
    render(conn, "index.json", tournament: tournaments)
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

    # TODO: tournament_topics.jsonのrenderを直接呼び出すのではなくshow.jsonからrender_manyをする方がよさそう
    render(conn, "tournament_topics.json", topics: tabs)
  end

  def start(conn, %{"tournament" => %{"master_id" => _master_id, "tournament_id" => tournament_id}}) do
    # マッチングリストを生成
    match_list =
      Tournaments.get_entrants(tournament_id)
      |>Enum.map(fn x -> x.id end)
      |>Tournaments.generate_matchlist()

    Ets.insert_match_list(tournament_id, match_list)
    render(conn, "match.json", list: match_list)
  end

  def delete_loser(conn, %{"tournament" => %{"match_list" => match_list, "loser_list" => loser_list}}) do
    updated_match_list =
      match_list
      |>Tournaments.delete_loser(loser_list)
    render(conn,"loser.json", list: updated_match_list)
  end

  def get_thumbnail_image(conn, %{"thumbnail_path" => path}) do
    case File.read("./static/image/tournament_thumbnail/#{path}.jpg") do
      {:ok, file} -> 
        b64 = Base.encode64(file)
        json(conn, %{b64: b64})
      {:error, _} -> 
        json(conn, %{error: "image not fonud"})
    end
  end
end

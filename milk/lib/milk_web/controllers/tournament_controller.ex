defmodule MilkWeb.TournamentController do
  use MilkWeb, :controller

  alias Milk.Ets
  alias Milk.Accounts
  alias Milk.Relations
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

  def get_tournaments_by_master_id(conn, %{"user_id" => user_id}) do
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

  def create(conn, %{"tournament" => tournament_params, "file" => file}) do
    create(conn, %{"tournament" => tournament_params, "image" => file})
  end
  def create(conn, %{"tournament" => tournament_params, "image" => image}) do
    thumbnail_path = if image != "" do
      uuid = SecureRandom.uuid()
      File.cp(image.path, "./static/image/tournament_thumbnail/#{uuid}.jpg")
      uuid
    else
      nil
    end

    IO.inspect(tournament_params)

    case Tournaments.create_tournament(tournament_params, thumbnail_path) do
      {:ok, %Tournament{} = tournament} ->
        t =
          tournament
          |> Map.put(:followers, Relations.get_followers(tournament.master_id))
          
        conn
        # |> put_status(:created)
        # |> put_resp_header("location", Routes.tournament_path(conn, :show, tournament))
        |> render("create.json", tournament: t)
      {:error, error} ->
        render(conn, "error.json", error: error)
      _ ->
        render(conn, "error.json", error: nil)
    end
  end

  # 現在参加中のユーザーもカウントする
  def show(conn, %{"tournament_id" => id}) do
    tournament = Tournaments.get_tournament!(id)

    if(tournament) do
      entrants = Tournaments.get_entrants(tournament.id)
      |> Enum.map(fn entrant -> 
        Accounts.get_user(entrant.user_id)
      end)

      render(conn, "tournament_info.json", tournament: tournament, entrants: entrants)
    else
      render(conn, "error.json", error: nil)
    end
  end

  # Gets tournament info list for home screen.
  def home(conn, %{"filter" => "fav", "user_id" => user_id}) do
    tournaments = 
    Tournaments.home_tournament_fav(user_id)
    |> Enum.map(fn tournament -> 
      entrants = 
        Tournaments.get_entrants(tournament.id)
        |> Enum.map(fn entrant -> 
          Accounts.get_user(entrant.user_id)
        end)
      
      %{
        tournament: tournament,
        entrants: entrants
      }
    end)

    render(conn, "home.json", tournaments_info: tournaments)
  end

  def home(conn, %{"filter" => "plan", "user_id" => user_id}) do
    tournaments = 
    Tournaments.home_tournament_plan(user_id)
    |> Enum.map(fn tournament -> 
      entrants = 
        Tournaments.get_entrants(tournament.id)
        |> Enum.map(fn entrant -> 
          Accounts.get_user(entrant.user_id)
        end)
      
      %{
        tournament: tournament,
        entrants: entrants
      }
    end)

    render(conn, "home.json", tournaments_info: tournaments)
  end
  
  def home(conn, params) do
    tournaments =
    Tournaments.home_tournament()
    |> Enum.map(fn tournament ->
      entrants =
        Tournaments.get_entrants(tournament.id)
        |> Enum.map(fn entrant ->
          Accounts.get_user(entrant.user_id)
        end)

      %{
        tournament: tournament,
        entrants: entrants
      }
    end)

    render(conn, "home.json", tournaments_info: tournaments)
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

  def start(conn, %{"tournament" => %{"master_id" => master_id, "tournament_id" => tournament_id}}) do
    with {:ok, _} <- Tournaments.start(master_id, tournament_id) do
      # マッチングリストを生成
      match_list =
        Tournaments.get_entrants(tournament_id)
        |> Enum.map(fn x -> x.id end)
        |> Tournaments.generate_matchlist()

      Ets.insert_match_list(tournament_id, match_list)
      render(conn, "match.json", list: match_list)
    else
      _ -> json(conn, %{error: "error"})
    end
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
        json(conn, %{error: "image not found"})
    end
  end

  def get_match_list(conn, %{"tournament_id" => tournament_id}) do
      Ets.get_match_list(tournament_id) 
      |> case do
        {_, match_list} -> json(conn, %{match_list: match_list, result: true})
        _ -> json(conn, %{match_list: nil, result: false})
      end
  end

  def publish_url(conn, _params) do
    url = SecureRandom.urlsafe_base64()

    json(conn, %{url: "http://localhost:4000/tournament/"<>url})
  end

  def get_match_members(conn, %{"tournament_id" => tournament_id}) do
    tournament = Tournaments.get_tournament(tournament_id)
  
    if(tournament) do
      master = Accounts.get_user(tournament.master_id)
      assistants = Tournaments.get_assistants(tournament.id)
      |> Enum.map(fn assistant ->
        Accounts.get_user(assistant.user_id)
      end)
      entrants = Tournaments.get_entrants(tournament.id)
      |> Enum.map(fn entrant -> 
        Accounts.get_user(entrant.user_id)
      end)

      render(conn, "tournament_members.json", master: master, assistants: assistants, entrants: entrants)
    else
      render(conn, "error.json", error: nil)
    end
  end
end

defmodule MilkWeb.TournamentController do
  use MilkWeb, :controller

  alias Milk.Ets
  alias Milk.Accounts
  alias Milk.Chat
  alias Milk.Log
  alias Milk.Relations
  alias Milk.Tournaments
  alias Milk.Tournaments.Tournament
  alias Common.Tools

  @doc """
  Get tournament list.
  """
  def index(conn,  _params) do
    tournament = Tournaments.list_tournament()
    if(tournament) do
      render(conn, "index.json", tournament: tournament)
    else
      render(conn, "error.json", error: nil)
    end
  end

  @doc """
  Get users for assistant.
  """
  def get_users_for_add_assistant(conn, %{"user_id" => user_id}) do
    following_users = Relations.get_following_list(user_id)
    follower_users = Relations.get_followers_list(user_id)
    users = Enum.uniq_by(follower_users ++ follower_users, fn user -> user.id end)
    render(conn,"users.json", users: users)
  end

  @doc """
  Get tournaments of a specific user.
  """
  def get_tournaments_by_master_id(conn, %{"user_id" => user_id}) do
    tournaments =
    Tournaments.get_tournaments_by_master_id(user_id)
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

  @doc """
  Get ongoing tournaments of a specific user.
  """
  def get_going_tournaments_by_master_id(conn, %{"user_id" => user_id}) do
    tournaments = Tournaments.get_going_tournaments_by_master_id(user_id)
    render(conn, "index.json", tournament: tournaments)
  end

  @doc """
  Get a game of a specific tournament.
  """
  def get_game(conn, %{"tournament" => params}) do
    tournament = Tournaments.game_tournament(params)
    if(tournament) do
      render(conn, "index.json", tournament: tournament)
    else
      render(conn, "error.json", error: nil)
    end
  end

  @doc """
  Create a tournament.
  """
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

    tournament_params = if is_binary(tournament_params), do: Poison.decode!(tournament_params), else: tournament_params

    case Tournaments.create_tournament(tournament_params, thumbnail_path) do
      {:ok, %Tournament{} = tournament} ->

        if tournament_params["join"] == "true" do
          params = %{"user_id" => tournament.master_id, "tournament_id" => tournament.id}
          Tournaments.create_entrant(params)
        end

        t =
          tournament
          |> Map.put(:followers, Relations.get_followers(tournament.master_id))
          
        conn
        |> render("create.json", tournament: t)
      {:error, error} ->
        render(conn, "error.json", error: error)
      _ ->
        render(conn, "error.json", error: nil)
    end
  end

  @doc """
  Show tournament information.
  """
  def show(conn, %{"tournament_id" => id}) do
    id = Tools.to_integer_as_needed(id)

    tournament = Tournaments.get_tournament!(id)
    tournament_log = Log.get_tournament_log_by_tournament_id(id)

    if tournament do
      entrants = Tournaments.get_entrants(tournament.id)
        |> Enum.map(fn entrant -> 
          Accounts.get_user(entrant.user_id)
        end)

      render(conn, "tournament_info.json", tournament: tournament, entrants: entrants)
    else
      if tournament_log do
        render(conn, "tournament_log.json", tournament_log: tournament_log)
      else
        render(conn, "error.json", error: nil)
      end
    end
  end

  # FIXME: フィルタの仕方変えたほうがよさそう
  @doc """
  Gets tournament info list for home screen.
  """
  def home(conn, %{"filter" => "fav", "user_id" => user_id}) do
    tournaments = 
    Tournaments.home_tournament_fav(user_id)
    |> Enum.map(fn tournament -> 
      entrants = 
        Tournaments.get_entrants(tournament.id)
        |> Enum.map(fn entrant -> 
          Accounts.get_user(entrant.user_id)
        end)
      
      %{tournament: tournament, entrants: entrants}
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
      
      %{tournament: tournament, entrants: entrants}
    end)

    render(conn, "home.json", tournaments_info: tournaments)
  end
  
  def home(conn, _params) do
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

  @doc """
  Update a tournament.
  """
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

  @doc """
  Deletes a tournament.
  """
  def delete(conn, %{"tournament_id" => id}) do
    with {:ok, %Tournament{}} <- Tournaments.delete_tournament(id) do
      send_resp(conn, :no_content, "")
    end
  end

  @doc """
  Send a image as a response.
  """
  def image(conn, %{"filename" => filename}) do
    path = "./static/image/tournament_thumbnail/#{filename}.jpg"

    conn
    |> put_resp_content_type("image/jpeg")
    |> send_file(200, path)
  end

  @doc """
  Get tournaments which a user is participating in.
  """
  def participating_tournaments(conn, %{"user_id" => user_id}) do
    tournaments =
    Tournaments.get_participating_tournaments!(user_id)
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

    if tournaments do
      render(conn, "home.json", tournaments_info: tournaments)
    else
      render(conn, "error.json", error: nil)
    end
  end

  @doc """
  Get tournament topics.
  """
  def tournament_topics(conn, %{"tournament_id" => tournament_id}) do
    tabs = Tournaments.get_tabs_by_tournament_id(tournament_id)

    # TODO: tournament_topics.jsonのrenderを直接呼び出すのではなくshow.jsonからrender_manyをする方がよさそう
    render(conn, "tournament_topics.json", topics: tabs)
  end

  @doc """
  Start a tournament.
  """
  def start(conn, %{"tournament" => %{"master_id" => master_id, "tournament_id" => tournament_id}}) do
    master_id = Tools.to_integer_as_needed(master_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    with {:ok, _} <- Tournaments.start(master_id, tournament_id) do
      # マッチングリストを生成
      match_list =
        Tournaments.get_entrants(tournament_id)
        |> Enum.map(fn x -> x.user_id end)
        |> Tournaments.generate_matchlist()

      Ets.insert_match_list(tournament_id, match_list)
      render(conn, "match.json", list: match_list)
    else
      _ -> json(conn, %{error: "error"})
    end
  end

  @doc """
  Delete losers of a loser list.
  """
  # FIXME: loserをリストじゃなくて整数で入力できるようにしたほうが良さそう
  def delete_loser(conn, %{"tournament" => %{"tournament_id" => tournament_id, "loser_list" => loser_list}}) do
    {_, match_list} = hd(Ets.get_match_list(tournament_id))
    # FIXME: ここのリストが空だったときのエラー処理どうやってやろうかな
    # match_list = unless match_list == [] do
    #   hd(match_list)
    # end

    # 不要な行を削除しておく
    match_list
    |> Tournaments.find_match(hd(loser_list))
    |> Enum.each(fn user_id -> 
      Ets.delete_match_pending_list(user_id)
      Ets.delete_fight_result(user_id)
    end)
    
    updated_match_list = Tournaments.delete_loser(match_list, loser_list)
    Ets.delete_match_list(tournament_id)
    Ets.insert_match_list(tournament_id, updated_match_list)

    render(conn, "loser.json", list: updated_match_list)
  end

  @doc """
  Find a match of a specific tournament.
  """
  def find_match(conn, %{"tournament_id" => tournament_id, "user_id" => user_id}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    user_id = Tools.to_integer_as_needed(user_id)

    {_, match_list} = hd(Ets.get_match_list(tournament_id))

    match = Tournaments.find_match(match_list, user_id)
    result = Tournaments.is_alone(match)

    json(conn, %{result: result, match: match})
  end

  @doc """
  Get a thumbnail image of a tournament.
  """
  def get_thumbnail_image(conn, %{"thumbnail_path" => path}) do
    case File.read("./static/image/tournament_thumbnail/#{path}.jpg") do
      {:ok, file} -> 
        b64 = Base.encode64(file)
        json(conn, %{b64: b64})
      {:error, _} ->
        json(conn, %{error: "image not found"})
    end
  end

  @doc """
  Get a match list of a tournament.
  """
  def get_match_list(conn, %{"tournament_id" => tournament_id}) do
    tournament_id = if is_binary(tournament_id) do
      String.to_integer(tournament_id)
    else
      tournament_id
    end
    list = Ets.get_match_list(tournament_id) 
    list = unless list == [] do
      hd(list)
    end

    case list do
      {_, match_list} -> json(conn, %{match_list: match_list, result: true})
      _ -> json(conn, %{match_list: nil, result: false})
    end
  end

  @doc """
  Start a single match in the tournament.
  """
  def start_match(conn, %{"user_id" => user_id, "tournament_id" => tournament_id}) do
    user_id = Tools.to_integer_as_needed(user_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    case Ets.get_match_pending_list(user_id) do
      [] ->
        Ets.insert_match_pending_list_table(tournament_id, user_id)
        json(conn, %{result: true})
      _ ->
        json(conn, %{result: false})
    end
  end

  
  def get_opponent(conn, %{"tournament_id" => tournament_id, "user_id" => user_id}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    user_id = Tools.to_integer_as_needed(user_id)

    {_, match_list} = hd(Ets.get_match_list(tournament_id))
    match = Tournaments.find_match(match_list, user_id)
    opponent = Tournaments.get_opponent(match, user_id)

    json(conn, %{result: true, opponent: opponent})
  end

  def claim_win(conn, %{"opponent_id" => opponent_id, "user_id" => user_id, "tournament_id" => tournament_id}) do
    opponent_id = Tools.to_integer_as_needed(opponent_id)
    user_id = Tools.to_integer_as_needed(user_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    case Ets.get_fight_result(opponent_id) do
      [] ->
        Ets.insert_fight_result_table(user_id, true)
        json(conn, %{validated: true, completed: false})

      result_list ->
        {_, is_win} = hd(result_list)

        if is_win do
          Chat.notify_game_masters(tournament_id)
          json(conn, %{validated: false, completed: false})
        else
          # マッチングが正常に終了している
          json(conn, %{validated: true, completed: true})
        end
    end
  end

  def claim_lose(conn, %{"opponent_id" => opponent_id, "user_id" => user_id, "tournament_id" => tournament_id}) do
    opponent_id = Tools.to_integer_as_needed(opponent_id)
    user_id = Tools.to_integer_as_needed(user_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    case Ets.get_fight_result(opponent_id) do
      [] ->
        Ets.insert_fight_result_table(user_id, false)
        json(conn, %{validated: true, completed: false})
      result_list ->
        {_, is_win} = hd(result_list)

        unless is_win do
          Chat.notify_game_masters(tournament_id)
          json(conn, %{validated: false, completed: false})
        else

          # マッチングが正常に終了している
          json(conn, %{validated: true, completed: true})
        end
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

  def get_game_masters(conn, %{"tournament_id" => tournament_id}) do
    master = 
      Tournaments.get_masters(tournament_id)

    assistants =
      Tournaments.get_assistants(tournament_id)
      |> Enum.map(fn assistant -> 
        Tournaments.get_user_info_of_assistant(assistant)
      end)

    masters = master ++ assistants

    render(conn, "masters.json", masters: masters)
  end

  def finish(conn, %{"tournament_id" => tournament_id, "user_id" => user_id}) do
    result =  Tournaments.finish(tournament_id, user_id)

    json(conn, %{result: result})
  end

  # DEBUG
  def debug_match_list(conn, %{"tournament_id" => _tournament_id}) do
    json(conn, %{match_list: [[1, 2], [[3, 4], [5, 6]]], result: true})
  end
end

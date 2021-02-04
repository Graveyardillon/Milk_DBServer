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
    users = Enum.uniq_by(following_users ++ follower_users, fn user -> user.id end)
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
  def get_ongoing_tournaments_by_master_id(conn, %{"user_id" => user_id}) do
    tournaments = Tournaments.get_ongoing_tournaments_by_master_id(user_id)
    render(conn, "index.json", tournament: tournaments)
  end

  @doc """
  Get a game of a specific tournament.
  FIXME: 引数をidに対応させたい
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
    if is_nil(tournament_params["join"]) do
      render(conn, "error.json", error: "join parameter is nil")
    else
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
  end

  @doc """
  Show tournament information.
  """
  def show(conn, %{"tournament_id" => id}) do
    id = Tools.to_integer_as_needed(id)

    tournament = Tournaments.get_tournament(id)
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

  # def home(conn, _params) do
  #   tournaments =
  #   Tournaments.home_tournament()
  #   |> Enum.map(fn tournament ->
  #     entrants =
  #       Tournaments.get_entrants(tournament.id)
  #       |> Enum.map(fn entrant ->
  #         Accounts.get_user(entrant.user_id)
  #       end)

  #     %{
  #       tournament: tournament,
  #       entrants: entrants
  #     }
  #   end)

  #   render(conn, "home.json", tournaments_info: tournaments)
  # end

  def home(conn, %{"date_offset" => date_offset, "offset" => offset}) do
    tournaments =
    Tournaments.home_tournament(date_offset, offset)
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
      #send_resp(conn, :no_content, "")
      json(conn, %{result: true})
    else
      _ -> render(conn, "error.json", error: nil)
    end
  end

  @doc """
  Send an image as a response.
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
  def participating_tournaments(conn, %{"user_id" => user_id, "offset" => offset}) do
    tournaments =
    Tournaments.get_participating_tournaments(user_id, offset)
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

  def participating_tournaments(conn, %{"user_id" => user_id}) do
    tournaments =
      Tournaments.get_participating_tournaments(user_id)
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
  Get relevant tournaments.
  """
  def relevant(conn, %{"user_id" => user_id}) do
    participatings = Tournaments.get_participating_tournaments(user_id)
    hostings = Tournaments.get_tournaments_by_master_id(user_id)

    tournaments = Enum.uniq(participatings ++ hostings)

    render(conn, "index.json", tournament: tournaments)
  end

  @doc """
  Get tournament topics.
  """
  def tournament_topics(conn, %{"tournament_id" => tournament_id}) do
    tabs = Tournaments.get_tabs_by_tournament_id(tournament_id)

    # TODO: tournament_topics.jsonのrenderを直接呼び出すのではなくshow.jsonからrender_manyをする方がよさそう
    render(conn, "tournament_topics.json", topics: tabs)
  end

  def tournament_update_topics(conn, %{"tournament_id" => tournament_id, "tabs" => tabs}) do
    tournament = Tournaments.get_tournament(tournament_id)
    if tournament do
      current_tabs = Tournaments.get_tabs_by_tournament_id(tournament_id)
      Tournaments.update_topic(tournament, current_tabs, tabs)

      tabs = Tournaments.get_tabs_by_tournament_id(tournament_id)
      render(conn, "tournament_topics.json", topics: tabs)
    else
      render(conn, "error.json", error: "tournament not found")
    end
  end

  @doc """
  Start a tournament.
  """
  def start(conn, %{"tournament" => %{"master_id" => master_id, "tournament_id" => tournament_id}}) do
    master_id = Tools.to_integer_as_needed(master_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    with {:ok, _} <- Tournaments.start(master_id, tournament_id) do
      make_matches(conn, tournament_id)
    else
      _ -> json(conn, %{error: "error"})
    end
  end

  defp make_matches(conn, tournament_id) do
    with {:ok, match_list} <-
      Tournaments.get_entrants(tournament_id)
      |> Enum.map(fn x -> x.user_id end)
      |> Tournaments.generate_matchlist() do
        count =
          Tournaments.get_tournament(tournament_id)
          |> Map.get(:count)
        match_list
        |> Tournaments.initialize_rank(count, tournament_id)
        match_list
        |> Ets.insert_match_list(tournament_id)

        list_with_fight_result =
          match_list
          |> match_list_with_fight_result()

        lis =
          list_with_fight_result
          |> Tournamex.match_list_to_list()

        complete_list =
          Enum.reduce(lis, list_with_fight_result, fn x, acc ->
            user = Accounts.get_user(x["user_id"])

            acc
            |> Tournaments.put_value_on_brackets(user.id, %{"name" => user.name})
            |> Tournaments.put_value_on_brackets(user.id, %{"win_count" => 0})
            |> Tournaments.put_value_on_brackets(user.id, %{"icon_path" => user.icon_path})
          end)
          |> Ets.insert_match_list_with_fight_result(tournament_id)

        render(conn, "match.json", %{match_list: match_list, match_list_with_fight_result: complete_list})
    else
      {:error, error} -> render(conn, "error.json", error: error)
    end
  end

  defp match_list_with_fight_result(match_list) do
    Tournaments.initialize_match_list_with_fight_result(match_list)
  end

  @doc """
  Delete losers of a loser list.
  FIXME: loserをリストじゃなくて整数で入力できるようにしたほうが良さそう
  """
  def delete_loser(conn, %{"tournament" => %{"tournament_id" => tournament_id, "loser_list" => loser_list}}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    loser_list = Enum.map(loser_list, fn loser ->
      Tools.to_integer_as_needed(loser)
    end)
    {_, match_list} = hd(Ets.get_match_list(tournament_id))

    match_list
    |> Tournaments.find_match(hd(loser_list))
    |> Enum.each(fn user_id ->
      Ets.delete_match_pending_list({user_id, tournament_id})
      Ets.delete_fight_result({user_id, tournament_id})
    end)

    updated_match_list = renew_match_list(tournament_id, match_list, loser_list)
    get_lost(tournament_id, match_list, loser_list)

    render(conn, "loser.json", list: updated_match_list)
  end

  defp renew_match_list(tournament_id, match_list, loser_list) do
    Tournaments.promote_winners_by_loser(tournament_id, match_list, loser_list)
    updated_match_list = Tournaments.delete_loser(match_list, loser_list)
    Ets.delete_match_list(tournament_id)
    Ets.insert_match_list(updated_match_list, tournament_id)
    updated_match_list
  end

  defp get_lost(tournament_id, _match_list, [loser]) do
    {_, match_list} =
      tournament_id
      |> Ets.get_match_list_with_fight_result()
      |> hd()
    updated_match_list = Tournaments.get_lost(match_list, loser)
    Ets.delete_match_list_with_fight_result(tournament_id)
    Ets.insert_match_list_with_fight_result(updated_match_list, tournament_id)
  end

  @doc """
  Find a match of a specific tournament.
  """
  def find_match(conn, %{"tournament_id" => tournament_id, "user_id" => user_id}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    user_id = Tools.to_integer_as_needed(user_id)

    {_, match_list} =
      tournament_id
      |> Ets.get_match_list()
      |> hd()

    match = Tournaments.find_match(match_list, user_id)
    result = Tournaments.is_alone?(match)

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
    tournament_id = Tools.to_integer_as_needed(tournament_id)

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

    pending_list = Ets.get_match_pending_list({user_id, tournament_id})

    if pending_list == [] do
      Ets.insert_match_pending_list_table({user_id, tournament_id})
      json(conn, %{result: true})
    else
      json(conn, %{result: false})
    end
  end

  @doc """
  Get an opponent of a tournament match.
  """
  def get_opponent(conn, %{"tournament_id" => tournament_id, "user_id" => user_id}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    user_id = Tools.to_integer_as_needed(user_id)

    {_, match_list} = hd(Ets.get_match_list(tournament_id))

    unless is_integer(match_list) do
      match = Tournaments.find_match(match_list, user_id)
      with {:ok, opponent} <- Tournaments.get_opponent(match, user_id) do
        json(conn, %{result: true, opponent: opponent})
      else
        {:wait, _} -> json(conn, %{result: false, opponent: nil})
        _ -> render(conn, "error.json", error: nil)
      end
    else
      json(conn, %{result: false})
    end
  end

  @doc """
  Check if the user has already matching.
  """
  def check_pending(conn, %{"user_id" => user_id, "tournament_id" => tournament_id}) do
    user_id = Tools.to_integer_as_needed(user_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    pending_list = Ets.get_match_pending_list({user_id, tournament_id})

    unless pending_list == [] do
      {{_, id}} = hd(pending_list)
      json(conn, %{result: true, tournament_id: id})
    else
      json(conn, %{result: false})
    end
  end

  @doc """
  Check if the user has already lost.
  """
  def has_lost?(conn, %{"user_id" => user_id, "tournament_id" => tournament_id}) do
    user_id = Tools.to_integer_as_needed(user_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    {_, match_list} = hd(Ets.get_match_list(tournament_id))

    has_lost = Tournaments.has_lost?(match_list, user_id)

    json(conn, %{has_lost: has_lost})
  end

  @doc """
  Check state of user in tournament.
  """
  def state(conn, %{"tournament_id" => tournament_id, "user_id" => user_id}) do
    user_id = Tools.to_integer_as_needed(user_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    state = Tournaments.state!(tournament_id, user_id)

    json(conn, %{result: true, state: state})
  end

  @doc """
  Claim win of the user.
  """
  def claim_win(conn, %{"opponent_id" => opponent_id, "user_id" => user_id, "tournament_id" => tournament_id}) do
    opponent_id = Tools.to_integer_as_needed(opponent_id)
    user_id = Tools.to_integer_as_needed(user_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    case Ets.get_fight_result({opponent_id, tournament_id}) do
      [] ->
        if Ets.get_fight_result({user_id, tournament_id}) != [] do
          Ets.delete_fight_result({user_id, tournament_id})
        end
        Ets.insert_fight_result_table({user_id, tournament_id}, true)
        json(conn, %{validated: true, completed: false})

      result_list ->
        {{_, _tournament_id}, is_win} = hd(result_list)

        if is_win do
          Chat.notify_game_masters(tournament_id)
          json(conn, %{validated: false, completed: false})
        else
          # マッチングが正常に終了している
          json(conn, %{validated: true, completed: true})
        end
    end
  end

  @doc """
  Claim lose of the user.
  """
  def claim_lose(conn, %{"opponent_id" => opponent_id, "user_id" => user_id, "tournament_id" => tournament_id}) do
    opponent_id = Tools.to_integer_as_needed(opponent_id)
    user_id = Tools.to_integer_as_needed(user_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    case Ets.get_fight_result({opponent_id, tournament_id}) do
      [] ->
        if Ets.get_fight_result({user_id, tournament_id}) != [] do
          Ets.delete_fight_result({user_id, tournament_id})
        end
        Ets.insert_fight_result_table({user_id, tournament_id}, false)
        json(conn, %{validated: true, completed: false})

      result_list ->
        {{_, _tournament_id}, is_win} = hd(result_list)

        unless is_win do
          Chat.notify_game_masters(tournament_id)
          json(conn, %{validated: false, completed: false})
        else
          json(conn, %{validated: true, completed: true})
        end
    end
  end

  @doc """
  Get a result of fight.
  """
  def is_user_win(conn, %{"user_id" => user_id, "tournament_id" => tournament_id}) do
    user_id = Tools.to_integer_as_needed(user_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    case Ets.get_fight_result({user_id, tournament_id}) do
      [] ->
        json(conn, %{is_win: nil, is_claimed: false})
      result_list ->
        {{_, tournament_id}, is_win} = hd(result_list)

        json(conn, %{is_win: is_win, tournament_id: tournament_id, is_claimed: true})
    end
  end

  @doc """
  Publish a url of a tournament.
  """
  def publish_url(conn, _params) do
    url = SecureRandom.urlsafe_base64()

    json(conn, %{url: "e-players://e-players/tournament/"<>url})
  end

  @doc """
  Get members of a match.
  """
  def get_match_members(conn, %{"tournament_id" => tournament_id}) do
    tournament = Tournaments.get_tournament(tournament_id)

    if tournament do
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

  @doc """
  Get game masters.
  """
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

  @doc """
  Finish tournament.
  """
  def finish(conn, %{"tournament_id" => tournament_id, "user_id" => user_id}) do
    result = Tournaments.finish(tournament_id, user_id)

    json(conn, %{result: result})
  end

  @doc """
  Get data with fight result for presenting tournament brackets.
  """
  def brackets_with_fight_result(conn, %{"tournament_id" => tournament_id}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    list = Ets.get_match_list_with_fight_result(tournament_id)
    list = unless list == [], do: hd(list)

    case list do
      {_, match_list} ->
        brackets = Tournaments.data_with_fight_result_for_brackets(match_list)
        count = Enum.count(brackets)*2
        num_for_brackets = Tournamex.Number.closest_number_to_power_of_two(count)

        json(conn, %{data: brackets, result: true, count: num_for_brackets})
      _ ->
        json(conn, %{data: nil, result: false, count: nil})
    end
  end

  @doc """
  Get data for presenting tournament brackets.
  """
  def brackets(conn, %{"tournament_id" => tournament_id}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    list = Ets.get_match_list(tournament_id)
    list = unless list == [], do: hd(list)

    case list do
      {_, match_list} ->
        brackets = Tournaments.data_for_brackets(match_list)
        count = Enum.count(brackets)*2
        num_for_brackets = Tournamex.Number.closest_number_to_power_of_two(count)

        json(conn, %{data: brackets, result: true, count: num_for_brackets})
      _ ->
        json(conn, %{data: nil, result: false, count: nil})
    end
  end

  # DEBUG
  # def debug_match_list(conn, %{"tournament_id" => _tournament_id}) do
  #   json(conn, %{match_list: [[1, 2], [[3, 4], [5, 6]]], result: true})
  # end

  def debug_match_list(conn, %{"tournament_id" => _tournament_id}) do
    json(conn, %{data: [[1, 2], [3, 4]], result: true})
  end
end

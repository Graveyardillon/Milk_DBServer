defmodule MilkWeb.TournamentController do
  use MilkWeb, :controller

  require Logger

  import Common.Sperm

  alias Milk.{
    Accounts,
    Chat,
    Log,
    Relations,
    TournamentProgress,
    Tournaments
  }

  alias Milk.CloudStorage.Objects
  alias Milk.Tournaments.Tournament
  alias Milk.Media.Image

  alias Common.{
    Tools,
    FileUtils
  }

  @doc """
  Get users for assistant.
  """
  def get_users_for_add_assistant(conn, %{"user_id" => user_id}) do
    user_id = Tools.to_integer_as_needed(user_id)

    following_users = Relations.get_following_list(user_id)
    follower_users = Relations.get_followers_list(user_id)
    users = Enum.uniq_by(following_users ++ follower_users, fn user -> user.id end)
    render(conn, "users.json", users: users)
  end

  @doc """
  Get tournaments of a specific user.
  """
  def get_tournaments_by_master_id(conn, %{"user_id" => user_id}) do
    tournaments =
      Tournaments.get_tournaments_by_master_id(user_id)
      |> (fn tournaments ->
            user_id
            |> Tournaments.get_tournaments_by_assistant_id()
            |> Enum.concat(tournaments)
          end).()
      |> Enum.uniq()
      |> Enum.map(fn tournament ->
        entrants =
          Tournaments.get_entrants(tournament.id)
          |> Enum.map(fn entrant ->
            Accounts.get_user(entrant.user_id)
          end)

        Map.put(tournament, :entrants, entrants)
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
  ユーザーの開催予定の大会と、logから今まで開催した大会のデータを取得
  """
  def get_planned_tournaments_by_master_id(conn, %{"user_id" => user_id}) do
    tournaments =
      user_id
      |> Tournaments.get_ongoing_tournaments_by_master_id()
      |> Enum.map(fn tournament ->
        entrants =
          tournament.id
          |> Tournaments.get_entrants()
          |> Enum.map(fn entrant ->
            Accounts.get_user(entrant.user_id)
          end)

        Map.put(tournament, :entrants, entrants)
      end)

    tournament_log = Tournaments.get_tournament_logs_by_master_id(user_id)

    render(conn, "tournament_include_log.json",
      tournaments: tournaments,
      tournament_log: tournament_log
    )
  end

  @doc """
  Create a tournament.
  """
  def create(conn, %{"tournament" => tournament_params, "file" => file}) do
    create(conn, %{"tournament" => tournament_params, "image" => file})
  end

  def create(conn, %{"tournament" => tournament_params, "image" => image}) do
    # coveralls-ignore-start
    thumbnail_path =
      if image != "" do
        uuid = SecureRandom.uuid()
        FileUtils.copy(image.path, "./static/image/tournament_thumbnail/#{uuid}.jpg")

        case Application.get_env(:milk, :environment) do
          :dev ->
            uuid

          # coveralls-ignore-stop
          :test ->
            uuid

          # coveralls-ignore-start
          _ ->
            object =
              Milk.CloudStorage.Objects.upload("./static/image/tournament_thumbnail/#{uuid}.jpg")

            File.rm("./static/image/tournament_thumbnail/#{uuid}.jpg")
            object.name
            # coveralls-ignore-stop
        end
      else
        nil
      end

    tournament_params =
      if is_binary(tournament_params),
        do: Poison.decode!(tournament_params),
        else: tournament_params

    if is_nil(tournament_params["join"]) do
      render(conn, "error.json", error: "join parameter is nil")
    else
      case Tournaments.create_tournament(tournament_params, thumbnail_path) do
        {:ok, %Tournament{} = tournament} ->
          if tournament_params["join"] == "true" do
            %{"user_id" => tournament.master_id, "tournament_id" => tournament.id}
            |> Tournaments.create_entrant()
          end

          tournament =
            tournament
            |> Map.put(:followers, Relations.get_followers(tournament.master_id))

          %{"user_id" => tournament.master_id, "game_name" => tournament.game_name, "score" => 7}
          |> Accounts.gain_score()

          render(conn, "create.json", tournament: tournament)

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
  def show(conn, params) do
    user_id = params["user_id"]
    id = Tools.to_integer_as_needed(params["tournament_id"])

    tournament = Tournaments.get_tournament(id)
    tournament_log = Log.get_tournament_log_by_tournament_id(id)

    if tournament do
      unless is_nil(user_id) do
        %{"user_id" => user_id, "game_name" => tournament.game_name, "score" => 1}
        |> Accounts.gain_score()
      end

      team = Enum.filter(tournament.team, fn team -> team.is_confirmed end)
      tournament = Map.put(tournament, :team, team)

      render(conn, "tournament_info.json", tournament: tournament)
    else
      if tournament_log do
        entrants = Log.get_entrant_logs_by_tournament_id(tournament_log.tournament_id)
        tournament_log = Map.put(tournament_log, :entrants, entrants)

        unless is_nil(user_id) do
          %{"user_id" => user_id, "game_name" => tournament_log.game_name, "score" => 1}
          |> Accounts.gain_score()
        end

        render(conn, "tournament_log.json", tournament_log: tournament_log)
      else
        render(conn, "error.json", error: nil)
      end
    end
  end

  @doc """
  Gets tournament info list for home screen.
  """
  def home(conn, %{"user_id" => user_id, "date_offset" => date_offset, "offset" => offset}) do
    user_id = Tools.to_integer_as_needed(user_id)
    offset = Tools.to_integer_as_needed(offset)

    tournaments =
      Tournaments.home_tournament(date_offset, offset, user_id)
      |> Enum.map(fn tournament ->
        entrants =
          Tournaments.get_entrants(tournament.id)
          |> Enum.map(fn entrant ->
            Accounts.get_user(entrant.user_id)
          end)

        Map.put(tournament, :entrants, entrants)
      end)

    render(conn, "home.json", tournaments_info: tournaments)
  end

  def home(conn, %{"date_offset" => date_offset, "offset" => offset}) do
    tournaments =
      Tournaments.home_tournament(date_offset, offset)
      |> Enum.map(fn tournament ->
        entrants =
          Tournaments.get_entrants(tournament.id)
          |> Enum.map(fn entrant ->
            Accounts.get_user(entrant.user_id)
          end)

        Map.put(tournament, :entrants, entrants)
      end)

    render(conn, "home.json", tournaments_info: tournaments)
  end

  def home(conn, %{"filter" => "fav", "user_id" => user_id}) do
    tournaments =
      Tournaments.home_tournament_fav(user_id)
      |> Enum.map(fn tournament ->
        entrants =
          Tournaments.get_entrants(tournament.id)
          |> Enum.map(fn entrant ->
            Accounts.get_user(entrant.user_id)
          end)

        Map.put(tournament, :entrants, entrants)
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

        Map.put(tournament, :entrants, entrants)
      end)

    render(conn, "home.json", tournaments_info: tournaments)
  end

  def home(conn, %{"filter" => "entry", "user_id" => user_id}) do
    tournaments =
      Tournaments.get_participating_tournaments(user_id)
      |> Enum.map(fn tournament ->
        entrants =
          Tournaments.get_entrants(tournament.id)
          |> Enum.map(fn entrant ->
            Accounts.get_user(entrant.user_id)
          end)

        Map.put(tournament, :entrants, entrants)
      end)

    if tournaments do
      render(conn, "home.json", tournaments_info: tournaments)
    else
      render(conn, "error.json", error: nil)
    end
  end

  @doc """
  Get searched tournaments as home.
  """
  def search(conn, %{"user_id" => user_id, "text" => text}) do
    tournaments =
      user_id
      |> Tournaments.search(text)
      |> Enum.map(fn tournament ->
        entrants =
          Tournaments.get_entrants(tournament.id)
          |> Enum.map(fn entrant ->
            Accounts.get_user(entrant.user_id)
          end)

        Map.put(tournament, :entrants, entrants)
      end)

    render(conn, "home.json", tournaments_info: tournaments)
  end

  @doc """
  Update a tournament.
  """
  def update(conn, %{"tournament_id" => id, "tournament" => tournament_params}) do
    tournament = Tournaments.get_tournament(id)

    if tournament do
      case tournament_params["join"] do
        "true" ->
          params = %{"user_id" => tournament.master_id, "tournament_id" => tournament.id}
          Tournaments.create_entrant(params)

        "false" ->
          Tournaments.delete_entrant(id, tournament_params["master_id"])

        _ ->
          nil
      end

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
      # send_resp(conn, :no_content, "")
      json(conn, %{result: true})
    else
      _ -> render(conn, "error.json", error: nil)
    end
  end

  @doc """
  Send an image as a response.
  FIXME: GCS対応
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

        Map.put(tournament, :entrants, entrants)
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

        Map.put(tournament, :entrants, entrants)
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
    user_id = Tools.to_integer_as_needed(user_id)

    tournaments = relevant(user_id)

    render(conn, "index.json", tournament: tournaments)
  end

  defp relevant(user_id) do
    participatings = Tournaments.get_participating_tournaments(user_id)
    hostings = Tournaments.get_tournaments_by_master_id(user_id)

    assistants =
      user_id
      |> Tournaments.get_assistants_by_user_id()
      |> Enum.map(fn assistant ->
        Tournaments.get_tournament(assistant.tournament_id)
      end)

    Enum.uniq(participatings ++ hostings ++ assistants)
  end

  @doc """
  Check whether the user can join the tournament.
  大会キャパシティチェック
  ユーザーの参加している他の大会との時間帯チェック
  """
  def is_able_to_join(conn, %{"user_id" => user_id, "tournament_id" => tournament_id}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    user_id = Tools.to_integer_as_needed(user_id)

    tournament = Tournaments.get_tournament(tournament_id)
    entrants = Tournaments.get_entrants(tournament.id)

    # キャパシティの確認(個人)
    result = tournament.capacity > length(entrants)

    # キャパシティの確認(チーム)
    result = tournament.capacity
      |> Kernel.>(length(tournament.team))
      |> Kernel.and(result)

    # 自分が参加しているかどうか
    result = entrants
      |> Enum.all?(fn entrant ->
        entrant.user_id != user_id
      end)
      |> Kernel.and(result)

    # 時刻の確認（自分の主催している大会には参加できる）
    result = user_id
      |> relevant()
      |> Enum.all?(fn t ->
        tournament.master_id == user_id || t.event_date != tournament.event_date
      end)
      |> Kernel.and(result)

    # 自分がチームとして参加しているかどうか
    result = user_id
      |> Tournaments.has_requested_as_team?(tournament_id)
      |> Kernel.not()
      |> Kernel.and(result)

    requested? = Tournaments.has_requested_as_team?(user_id, tournament_id)

    json(conn, %{result: result, has_requested_as_team: requested?})
  end

  @doc """
  Checks if the user is related to a started tournament.
  """
  def is_started_at_least_one(conn, %{"user_id" => user_id}) do
    user_id = Tools.to_integer_as_needed(user_id)

    tournaments =
      user_id
      |> relevant()
      |> Enum.filter(fn tournament ->
        tournament.is_started
      end)
      |> Enum.map(fn tournament ->
        tournament.id
      end)

    result = tournaments != []
    tournament_id = if result, do: hd(tournaments)

    json(conn, %{result: result, tournament_id: tournament_id})
  end

  @doc """
  Get tournament topics.
  """
  def tournament_topics(conn, %{"tournament_id" => tournament_id, "user_id" => user_id}) do
    tabs =
      tournament_id
      |> Tools.to_integer_as_needed()
      |> Tournaments.get_tabs_by_tournament_id()
      |> Enum.map(fn tab ->
        chat_room = Chat.get_chat_room(tab.chat_room_id)
        member = Chat.get_member(chat_room.id, user_id)

        tab
        |> Map.put(:authority, chat_room.authority)
        |> Map.put(:can_speak, chat_room.authority <= member.authority)
      end)

    render(conn, "tournament_topics.json", topics: tabs)
  end

  @doc """
  Update tournament topics.
  """
  def tournament_update_topics(conn, %{"tournament_id" => tournament_id, "tabs" => tabs}) do
    tournament = Tournaments.get_tournament(tournament_id)

    if tournament do
      current_tabs = Tournaments.get_tabs_by_tournament_id(tournament_id)
      Tournaments.update_topic(tournament, current_tabs, tabs)

      tabs =
        tournament_id
        |> Tournaments.get_tabs_by_tournament_id()
        |> Enum.map(fn tab ->
          chat_room = Chat.get_chat_room(tab.chat_room_id)

          tab
          |> Map.put(:authority, chat_room.authority)
          # 自分より権限が大きいルームは作成しないのでtrueを入れておく
          |> Map.put(:can_speak, true)
        end)

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

    tournament_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.get_tournament()
    ~> tournament
    |> Map.get(:is_team)
    |> if do
      start_team_tournament(master_id, tournament)
    else
      start_tournament(master_id, tournament)
    end
    |> case do
      {:ok, match_list, match_list_with_fight_result} ->
        render(conn, "match.json", %{match_list: match_list, match_list_with_fight_result: match_list_with_fight_result})
      {:error, nil, nil} ->
        render(conn, "error.json", error: nil)
      {:error, error, nil} ->
        render(conn, "error.json", error: Tools.create_error_message(error))
    end
  end

  defp start_team_tournament(_master_id, _tournament) do
    {:error, "unsupported tournament type", nil}
  end

  defp start_tournament(master_id, tournament) do
    case tournament.type do
      1 -> TournamentProgress.start_single_elimination(master_id, tournament)
      2 -> TournamentProgress.start_best_of_format(master_id, tournament)
      _ -> {:error, "unsupported tournament type", nil}
    end
  end

  @doc """
  Delete losers of a loser list.
  """
  def delete_loser(conn, %{
        "tournament" => %{"tournament_id" => tournament_id, "loser_list" => loser}
      })
      when is_binary(loser) or is_integer(loser) do
    delete_loser(conn, %{
      "tournament" => %{"tournament_id" => tournament_id, "loser_list" => [loser]}
    })
  end

  def delete_loser(conn, %{
        "tournament" => %{"tournament_id" => tournament_id, "loser_list" => loser_list}
      }) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    loser_list =
      Enum.map(loser_list, fn loser ->
        Tools.to_integer_as_needed(loser)
      end)

    tournament_id
    |> Tournaments.get_tournament()
    |> (fn tournament ->
          if tournament.type == 1 do
            store_single_tournament_match_log(tournament_id, hd(loser_list))
          end
        end).()

    updated_match_list = Tournaments.delete_loser_process(tournament_id, loser_list)
    render(conn, "loser.json", list: updated_match_list)
  end

  defp store_single_tournament_match_log(tournament_id, loser_list) when is_list(loser_list) do
    store_single_tournament_match_log(tournament_id, hd(loser_list))
  end

  defp store_single_tournament_match_log(tournament_id, loser_id) when is_integer(loser_id) do
    match_list = TournamentProgress.get_match_list(tournament_id)

    {:ok, winner} =
      match_list
      |> Tournaments.find_match(loser_id)
      |> Tournaments.get_opponent(loser_id)

    match_list_str = inspect(match_list, charlists: false)

    Map.new()
    |> Map.put("tournament_id", tournament_id)
    |> Map.put("loser_id", loser_id)
    |> Map.put("winner_id", winner["id"])
    |> Map.put("match_list_str", match_list_str)
    |> TournamentProgress.create_single_tournament_match_log()
  end

  @doc """
  Find a match of a specific tournament.
  """
  def find_match(conn, %{"tournament_id" => tournament_id, "user_id" => user_id}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    user_id = Tools.to_integer_as_needed(user_id)

    case TournamentProgress.get_match_list(tournament_id) do
      [] ->
        json(conn, %{result: false, match: nil})

      match_list when is_list(match_list) ->
        match = Tournaments.find_match(match_list, user_id)
        result = Tournaments.is_alone?(match)

        json(conn, %{result: result, match: match})

      _value ->
        json(conn, %{result: false, match: nil})
    end
  end

  @doc """
  Get a thumbnail image of a tournament.
  """
  def get_thumbnail_image(conn, %{"thumbnail_path" => path}) do
    map =
      case Application.get_env(:milk, :environment) do
        # coveralls-ignore-start
        :dev ->
          read_thumbnail(path)

        # coveralls-ignore-stop
        :test ->
          read_thumbnail(path)

        # coveralls-ignore-start
        _ ->
          read_thumbnail_prod(path)
          # coveralls-ignore-stop
      end

    json(conn, map)
  end

  defp read_thumbnail(name) do
    File.read("./static/image/tournament_thumbnail/#{name}.jpg")
    |> case do
      {:ok, file} ->
        b64 = Base.encode64(file)
        %{b64: b64}

      {:error, _} ->
        %{error: "image not found"}
    end
  end

  #  coveralls-ignore-start
  defp read_thumbnail_prod(name) do
    object = Objects.get(name)

    case Image.get(object.mediaLink) do
      {:ok, file} ->
        b64 = Base.encode64(file)
        %{b64: b64}

      _ ->
        %{error: "image not found"}
    end
  end

  # coveralls-ignore-stop

  @doc """
  Get a match list of a tournament.
  """
  def get_match_list(conn, %{"tournament_id" => tournament_id}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    match_list = TournamentProgress.get_match_list(tournament_id)

    if match_list == [] do
      json(conn, %{match_list: nil, result: false})
    else
      json(conn, %{match_list: match_list, result: true})
    end
  end

  @doc """
  Start a single match in the tournament.
  """
  def start_match(conn, %{"user_id" => user_id, "tournament_id" => tournament_id}) do
    user_id = Tools.to_integer_as_needed(user_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    pending_list = TournamentProgress.get_match_pending_list(user_id, tournament_id)

    if pending_list == [] do
      TournamentProgress.insert_match_pending_list_table(user_id, tournament_id)
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

    match_list = TournamentProgress.get_match_list(tournament_id)

    unless is_integer(match_list) do
      match = Tournaments.find_match(match_list, user_id)

      with {:ok, opponent} <- Tournaments.get_opponent(match, user_id) do
        json(conn, %{result: true, opponent: opponent})
      else
        # FIXME: waitのタプルの作り方微妙
        {:wait, _} -> json(conn, %{result: false, opponent: nil, wait: true})
        _ -> render(conn, "error.json", error: nil)
      end
    else
      json(conn, %{result: false})
    end
  end

  @doc """
  Get fighting users.
  """
  def get_fighting_users(conn, %{"tournament_id" => tournament_id}) do
    tournament_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.get_fighting_users()
    |> case do
      [] -> json(conn, %{data: [], result: true})
      users -> render(conn, "users.json", users: users)
    end
  end

  @doc """
  Get waiting users for fighting ones.
  """
  def get_waiting_users(conn, %{"tournament_id" => tournament_id}) do
    tournament_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.get_waiting_users()
    |> case do
      [] -> json(conn, %{data: [], result: true})
      users -> render(conn, "users.json", users: users)
    end
  end

  @doc """
  Check if the user has already matching.
  """
  def check_pending(conn, %{"user_id" => user_id, "tournament_id" => tournament_id}) do
    user_id = Tools.to_integer_as_needed(user_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    pending_list = TournamentProgress.get_match_pending_list(user_id, tournament_id)

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

    match_list = TournamentProgress.get_match_list(tournament_id)

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
    score = if state == "IsPending" do
      tournament_id
      |> TournamentProgress.get_score(user_id)
      |> case do
        [] -> nil
        score -> score
      end
    end

    json(conn, %{result: true, state: state, score: score})
  end

  @doc """
  Claim win of the user.
  """
  def claim_win(conn, %{
        "opponent_id" => opponent_id,
        "user_id" => user_id,
        "tournament_id" => tournament_id
      }) do
    opponent_id = Tools.to_integer_as_needed(opponent_id)
    user_id = Tools.to_integer_as_needed(user_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    case TournamentProgress.get_fight_result(opponent_id, tournament_id) do
      [] ->
        if TournamentProgress.get_fight_result(user_id, tournament_id) != [] do
          TournamentProgress.delete_fight_result(user_id, tournament_id)
        end

        TournamentProgress.insert_fight_result_table(user_id, tournament_id, true)
        json(conn, %{validated: true, completed: false})

      result_list ->
        {{_, _tournament_id}, is_win} = hd(result_list)
        TournamentProgress.delete_fight_result(user_id, tournament_id)
        TournamentProgress.delete_fight_result(opponent_id, tournament_id)

        if is_win do
          TournamentProgress.add_duplicate_user_id(tournament_id, user_id)
          TournamentProgress.add_duplicate_user_id(tournament_id, opponent_id)
          json(conn, %{validated: false, completed: false})
        else
          # マッチングが正常に終了している
          TournamentProgress.delete_match_pending_list(user_id, tournament_id)
          TournamentProgress.delete_match_pending_list(opponent_id, tournament_id)
          TournamentProgress.delete_duplicate_user(tournament_id, user_id)
          TournamentProgress.delete_duplicate_user(tournament_id, opponent_id)
          json(conn, %{validated: true, completed: true})
        end
    end
  end

  @doc """
  Claim lose of the user.
  """
  def claim_lose(conn, %{
        "opponent_id" => opponent_id,
        "user_id" => user_id,
        "tournament_id" => tournament_id
      }) do
    opponent_id = Tools.to_integer_as_needed(opponent_id)
    user_id = Tools.to_integer_as_needed(user_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    case TournamentProgress.get_fight_result(opponent_id, tournament_id) do
      [] ->
        if TournamentProgress.get_fight_result(user_id, tournament_id) != [] do
          TournamentProgress.delete_fight_result(user_id, tournament_id)
        end

        TournamentProgress.insert_fight_result_table(user_id, tournament_id, false)
        json(conn, %{validated: true, completed: false})

      result_list ->
        {{_, _tournament_id}, is_win} = hd(result_list)

        unless is_win do
          TournamentProgress.add_duplicate_user_id(tournament_id, user_id)
          TournamentProgress.add_duplicate_user_id(tournament_id, opponent_id)
          json(conn, %{validated: false, completed: false})
        else
          TournamentProgress.delete_match_pending_list(user_id, tournament_id)
          TournamentProgress.delete_match_pending_list(opponent_id, tournament_id)
          TournamentProgress.delete_fight_result(user_id, tournament_id)
          TournamentProgress.delete_fight_result(opponent_id, tournament_id)
          json(conn, %{validated: true, completed: true})
        end
    end
  end

  @doc """
  Claims score

  1. スコアをredisに登録する
  2. 相手もスコアを登録していたらマッチが進む
  """
  def claim_score(conn, %{
        "tournament_id" => tournament_id,
        "user_id" => user_id,
        "opponent_id" => opponent_id,
        "score" => score,
        "match_index" => match_index
      }) do
    user_id = Tools.to_integer_as_needed(user_id)
    opponent_id = Tools.to_integer_as_needed(opponent_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    score = Tools.to_integer_as_needed(score)
    match_index = Tools.to_integer_as_needed(match_index)

    TournamentProgress.insert_score(tournament_id, user_id, score)

    tournament_id
    |> TournamentProgress.get_score(opponent_id)
    |> case do
      n when is_integer(n) ->
        cond do
          n > score ->
            Tournaments.delete_loser_process(tournament_id, [user_id])
            Tournaments.score(tournament_id, opponent_id, user_id, n, score, match_index)
            TournamentProgress.delete_match_pending_list(user_id, tournament_id)
            TournamentProgress.delete_match_pending_list(opponent_id, tournament_id)
            TournamentProgress.delete_score(tournament_id, user_id)
            TournamentProgress.delete_score(tournament_id, opponent_id)
            finish_as_needed(tournament_id, opponent_id)
            json(conn, %{validated: true, completed: true})

          n < score ->
            Tournaments.delete_loser_process(tournament_id, [opponent_id])
            Tournaments.score(tournament_id, user_id, opponent_id, score, n, match_index)
            TournamentProgress.delete_match_pending_list(user_id, tournament_id)
            TournamentProgress.delete_match_pending_list(opponent_id, tournament_id)
            TournamentProgress.delete_score(tournament_id, user_id)
            TournamentProgress.delete_score(tournament_id, opponent_id)
            finish_as_needed(tournament_id, user_id)
            json(conn, %{validated: true, completed: true})

          true ->
            json(conn, %{validated: false, completed: false})
        end

      [] ->
        json(conn, %{validated: true, completed: false})
    end
  end

  defp finish_as_needed(tournament_id, winner_id) do
    match_list = TournamentProgress.get_match_list(tournament_id)

    if is_integer(match_list) do
      Tournaments.finish(tournament_id, winner_id)

      tournament_id
      |> TournamentProgress.get_match_list_with_fight_result()
      |> inspect(charlists: false)
      |> (fn str ->
            %{"tournament_id" => tournament_id, "match_list_with_fight_result_str" => str}
          end).()
      |> TournamentProgress.create_match_list_with_fight_result_log()

      TournamentProgress.delete_match_list(tournament_id)
      TournamentProgress.delete_match_list_with_fight_result(tournament_id)
      TournamentProgress.delete_match_pending_list_of_tournament(tournament_id)
      TournamentProgress.delete_fight_result_of_tournament(tournament_id)
      TournamentProgress.delete_duplicate_users_all(tournament_id)
      TournamentProgress.delete_lose_processes(tournament_id)
    end

    if match_list == [] do
      Logger.error("Match list error on finish as needed")
    end
  end

  @doc """
  Force to defeat a user.
  """
  def force_to_defeat(conn, %{
        "tournament_id" => tournament_id,
        "target_user_id" => target_user_id
      }) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    target_user_id = Tools.to_integer_as_needed(target_user_id)

    tournament_id
    |> TournamentProgress.get_match_list()
    |> Tournaments.find_match(target_user_id)
    |> Tournaments.get_opponent(target_user_id)
    |> case do
      {:ok, winner} ->
        Tournaments.promote_rank(%{"tournament_id" => tournament_id, "user_id" => winner["id"]})
        Tournaments.score(tournament_id, winner["id"], target_user_id, 0, -1, 0)
        Tournaments.delete_loser_process(tournament_id, [target_user_id])
        finish_as_needed(tournament_id, winner["id"])

      {:wait, nil} ->
        match =
          tournament_id
          |> TournamentProgress.get_match_list()
          |> Tournaments.find_match(target_user_id)
          |> Kernel.--([target_user_id])
          |> hd()
          |> Enum.each(fn user_id ->
            Tournaments.promote_rank(
              %{"tournament_id" => tournament_id, "user_id" => user_id},
              :force
            )
          end)

        Tournaments.delete_loser_process(tournament_id, [target_user_id])
    end

    json(conn, %{result: true})
  end

  @doc """
  Get a tournament by url.
  """
  def get_tournament_by_url(conn, %{"url" => url}) do
    tournament = Tournaments.get_tournament_by_url(url)
    render(conn, "tournament_info.json", tournament: tournament)
  end

  @doc """
  Get a result of fight.
  """
  def is_user_win(conn, %{"user_id" => user_id, "tournament_id" => tournament_id}) do
    user_id = Tools.to_integer_as_needed(user_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    case TournamentProgress.get_fight_result(user_id, tournament_id) do
      [] ->
        json(conn, %{is_win: nil, is_claimed: false})

      result_list ->
        {{_, tournament_id}, is_win} = hd(result_list)

        json(conn, %{is_win: is_win, tournament_id: tournament_id, is_claimed: true})
    end
  end

  @doc """
  Get score of a user.
  """
  def score(conn, %{"tournament_id" => tournament_id, "user_id" => user_id}) do
    user_id = Tools.to_integer_as_needed(user_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    TournamentProgress.get_score(tournament_id, user_id)
    |> case do
      [] -> json(conn, %{score: nil, result: false})
      score -> json(conn, %{score: score, result: true})
    end
  end

  @doc """
  Publish a url of a tournament.
  """
  def publish_url(conn, _params) do
    url = SecureRandom.urlsafe_base64()

    json(conn, %{url: "e-players://e-players/tournament/" <> url, result: true})
  end

  @doc """
  Get members of a match.
  """
  def get_match_members(conn, %{"tournament_id" => tournament_id}) do
    tournament = Tournaments.get_tournament(tournament_id)

    if tournament do
      master = Accounts.get_user(tournament.master_id)

      assistants =
        Tournaments.get_assistants(tournament.id)
        |> Enum.map(fn assistant ->
          Accounts.get_user(assistant.user_id)
        end)

      entrants =
        Tournaments.get_entrants(tournament.id)
        |> Enum.map(fn entrant ->
          Accounts.get_user(entrant.user_id)
        end)

      render(conn, "tournament_members.json",
        master: master,
        assistants: assistants,
        entrants: entrants
      )
    else
      render(conn, "error.json", error: nil)
    end
  end

  @doc """
  Get duplicate members.
  """
  def get_duplicate_claim_members(conn, %{"tournament_id" => tournament_id}) do
    users =
      tournament_id
      |> TournamentProgress.get_duplicate_users()
      |> Enum.map(fn user_id ->
        Accounts.get_user(user_id)
      end)

    render(conn, "users.json", users: users)
  end

  @doc """
  Get game masters.
  """
  def get_game_masters(conn, %{"tournament_id" => tournament_id}) do
    master = Tournaments.get_masters(tournament_id)

    assistants =
      Tournaments.get_assistants(tournament_id)
      |> Enum.map(fn assistant ->
        Tournaments.get_user_info_of_assistant(assistant)
      end)

    masters = master ++ assistants

    render(conn, "masters.json", masters: masters)
  end

  @doc """
  Get tournament entrants.
  """
  def get_entrants(conn, %{"tournament_id" => tournament_id}) do
    entrants =
      tournament_id
      |> Tools.to_integer_as_needed()
      |> Tournaments.get_entrants()

    render(conn, "entrants.json", entrants: entrants)
  end

  @doc """
  Finish tournament.
  """
  def finish(conn, %{"tournament_id" => tournament_id, "user_id" => user_id}) do
    result = Tournaments.finish(tournament_id, user_id)

    tournament_id
    |> TournamentProgress.get_match_list_with_fight_result()
    |> inspect(charlists: false)
    |> (fn str ->
          %{"tournament_id" => tournament_id, "match_list_with_fight_result_str" => str}
        end).()
    |> TournamentProgress.create_match_list_with_fight_result_log()

    TournamentProgress.delete_match_list(tournament_id)
    TournamentProgress.delete_match_list_with_fight_result(tournament_id)
    TournamentProgress.delete_match_pending_list_of_tournament(tournament_id)
    TournamentProgress.delete_fight_result_of_tournament(tournament_id)
    TournamentProgress.delete_duplicate_users_all(tournament_id)
    TournamentProgress.delete_lose_processes(tournament_id)

    json(conn, %{result: result})
  end

  @doc """
  Get data with fight result for presenting tournament brackets.
  """
  def brackets_with_fight_result(conn, %{"tournament_id" => tournament_id}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    match_list = TournamentProgress.get_match_list_with_fight_result(tournament_id)

    if match_list == [] do
      json(conn, %{data: nil, result: false, count: nil})
    else
      brackets = Tournaments.data_with_fight_result_for_brackets(match_list)
      count = Enum.count(brackets) * 2
      num_for_brackets = Tournamex.Number.closest_number_to_power_of_two(count)

      json(conn, %{data: brackets, result: true, count: num_for_brackets})
    end
  end

  @doc """
  Bracket data for best of format.
  """
  def chunk_bracket_data_for_best_of_format(conn, %{"tournament_id" => tournament_id}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    brackets = Tournaments.data_with_scores_for_flexible_brackets(tournament_id)

    count =
      brackets
      |> Enum.count()
      |> Kernel.*(2)
      |> Tournamex.Number.closest_number_to_power_of_two()

    json(conn, %{result: true, data: brackets, count: count})
  end

  @doc """
  テスト用 Idの数だけのブラケットを返す
  """
  def chunk_bracket_data_for_best_of_format_test(conn, %{"tournament_id" => number}) do
    num = Tools.to_integer_as_needed(number)

    Enum.to_list(1..num)
    |> Tournamex.generate_matchlist()
    |> elem(1)
    |> IO.inspect(charlists: false)
    |> Tournamex.brackets()
    |> elem(1)
    |> IO.inspect(charlists: false)

    match_list =
      1..num
      |> Enum.to_list()
      |> Tournamex.generate_matchlist()
      |> elem(1)
      |> Tournamex.initialize_match_list_with_fight_result()

    match_list =
      match_list
      |> List.flatten()
      |> Enum.reduce(match_list, fn x, acc ->
        user_id = x["user_id"]

        acc
        |> Milk.Tournaments.put_value_on_brackets(user_id, %{
          "name" => "name" <> to_string(user_id)
        })
        |> Milk.Tournaments.put_value_on_brackets(user_id, %{"win_count" => 0})
        |> Milk.Tournaments.put_value_on_brackets(user_id, %{"icon_path" => nil})
        |> Milk.Tournaments.put_value_on_brackets(user_id, %{"round" => 0})
        |> Milk.Tournaments.put_value_on_brackets(user_id, %{"game_scores" => [0]})
      end)
      |> Tournamex.brackets_with_fight_result()
      |> elem(1)
      |> List.flatten()

    json(conn, %{result: true, data: match_list, count: 0})
  end

  @doc """
  Registers PID of start notification.
  The notification is handled in Web Server, so the pid does not belong to this server.
  """
  def register_pid_of_start_notification(conn, %{"tournament_id" => tournament_id, "pid" => pid}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    # FIXME: エラーハンドリング
    tournament_id
    |> Tournaments.get_tournament()
    |> Tournaments.update_tournament(%{"start_notification_pid" => pid})
    |> case do
      {:ok, _tournament} -> json(conn, %{result: true})
      {:error, nil} -> json(conn, %{result: false})
      {:error, _error} -> json(conn, %{result: false})
    end
  end

  def verify_password(conn, %{"tournament_id" => tournament_id, "password" => password}) do
    result =
      tournament_id
      |> Tools.to_integer_as_needed()
      |> Tournaments.verify?(password)

    json(conn, %{result: result})
  end
end

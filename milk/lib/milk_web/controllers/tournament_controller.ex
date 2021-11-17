defmodule MilkWeb.TournamentController do
  @moduledoc """
  Tournament Controller
  """
  use MilkWeb, :controller
  use Timex

  require Logger

  import Common.Sperm

  alias Milk.{
    Accounts,
    Chat,
    Discord,
    Log,
    Notif,
    Relations,
    Tournaments
  }

  alias Milk.Accounts.User
  alias Milk.CloudStorage.Objects
  alias Milk.Log.{
    TeamLog,
    TournamentLog
  }
  alias Milk.Tournaments.{
    Claim,
    MatchInformation,
    Progress,
    Team,
    Tournament
  }

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
    user_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.get_tournaments_by_master_id()
    |> Enum.map(fn tournament ->
      tournament.id
      |> Tournaments.get_entrants()
      |> Enum.map(&Accounts.get_user(&1.user_id))
      ~> entrants

      Map.put(tournament, :entrants, entrants)
    end)
    ~> tournaments

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
    user_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.get_ongoing_tournaments_by_master_id()
    |> Enum.map(fn tournament ->
      tournament.id
      |> Tournaments.get_entrants()
      |> Enum.map(&Accounts.get_user(&1.user_id))
      ~> entrants

      Map.put(tournament, :entrants, entrants)
    end)
    ~> tournaments

    tournament_log = Tournaments.get_tournament_logs_by_master_id(user_id)

    render(conn, "tournament_include_log.json",
      tournaments: tournaments,
      tournament_log: tournament_log
    )
  end

  @doc """
  Create a tournament.
  """
  def create(conn, %{"tournament" => attrs, "file" => file, "maps" => maps}),
    do: __MODULE__.create(conn, %{"tournament" => attrs, "image" => file, "maps" => maps})
  def create(conn, %{"tournament" => attrs, "file" => file}),
    do: __MODULE__.create(conn, %{"tournament" => attrs, "image" => file, "maps" => []})
  # NOTE: サムネイル画像がない場合の大会作成処理
  def create(conn, %{"tournament" => attrs, "image" => image, "maps" => maps}) when image == "" or is_nil(image) do
    attrs = Tools.parse_json_string_as_needed!(attrs)

    do_create(conn, attrs, nil, maps)
  end

  # NOTE: サムネイル画像がある場合の大会作成処理
  def create(conn, %{"tournament" => attrs, "image" => image, "maps" => maps}) do
    thumbnail_path = store_thumbnail(image)
    attrs = Tools.parse_json_string_as_needed!(attrs)

    do_create(conn, attrs, thumbnail_path, maps)
  end

  defp store_thumbnail(image) do
    uuid = SecureRandom.uuid()
    thumbnail_path = "./static/image/tournament_thumbnail/#{uuid}.jpg"
    FileUtils.copy(image.path, thumbnail_path)

    case Application.get_env(:milk, :environment) do
      # coveralls-ignore-start
      :dev -> thumbnail_path
      # coveralls-ignore-stop
      :test -> thumbnail_path
      # coveralls-ignore-start
      _ ->
        {:ok, object} = Milk.CloudStorage.Objects.upload("./static/image/tournament_thumbnail/#{uuid}.jpg")

        File.rm("./static/image/tournament_thumbnail/#{uuid}.jpg")
        object.name
        # coveralls-ignore-stop
    end
  end

  defp do_create(conn, %{"join" => join?, "enabled_coin_toss" => enabled_coin_toss, "enabled_map" => enabled_map} = tournament_params, thumbnail_path, maps) do
    tournament_params
    |> Map.put("enabled_coin_toss", enabled_coin_toss == "true" || enabled_coin_toss == true)
    |> Map.put("enabled_map", enabled_map == "true" || enabled_map == true)
    |> Map.put("maps", maps)
    |> Tournaments.create_tournament(thumbnail_path)
    |> case do
      {:ok, %Tournament{master_id: master_id, id: id, game_name: game_name} = tournament} ->
        if join? == "true", do: Tournaments.create_entrant(%{"user_id" => master_id, "tournament_id" => id})

        followers = Relations.get_followers(master_id)
        tournament = Map.put(tournament, :followers, followers)

        Accounts.gain_score(%{
          "user_id" => master_id,
          "game_name" => game_name,
          "score" => 7
        })

        add_queue_tournament_start_push_notice(tournament)
        discord_process_on_create(tournament)

        render(conn, "create.json", tournament: tournament)

      {:error, error} -> render(conn, "error.json", error: error)
    end
  end
  defp do_create(conn, %{"join" => join?} = attrs, thumbnail_path, maps) do
    attrs
    |> Map.put("join", join?)
    |> Map.put("enabled_coin_toss", attrs["enabled_coin_toss"])
    |> Map.put("enabled_map", attrs["enabled_map"])
    ~> attrs

    do_create(conn, attrs, thumbnail_path, maps)
  end
  defp do_create(conn, _, _, _), do: render(conn, "error.json", error: "join parameter is nil")

  defp discord_process_on_create(%Tournament{discord_server_id: discord_server_id, description: description}) when is_nil(discord_server_id) or is_nil(description), do: nil
  defp discord_process_on_create(%Tournament{discord_server_id: discord_server_id, description: description}) do
    Task.async(fn ->
      discord_server_id
      |> Discord.send_tournament_create_notification()
      |> case do
        {:ok, _}    -> Discord.send_tournament_description(discord_server_id, description)
        {:error, _} -> nil
      end
    end)
  end

  @doc """
  Show tournament information.
  """
  def show(conn, %{"user_id" => user_id, "tournament_id" => tournament_id}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    tournament_id
    |> Tournaments.get_tournament_including_logs()
    |> case do
      {:ok, %Tournament{} = tournament} ->
        unless is_nil(user_id) do
          user_id = Tools.to_integer_as_needed(user_id)

          Accounts.gain_score(%{"user_id" => user_id, "game_name" => tournament.game_name, "score" => 1})
        end

        team = Enum.filter(tournament.team, fn team -> team.is_confirmed end)

        tournament.id
        |> Tournaments.get_maps_by_tournament_id()
        |> Enum.map(&Map.put(&1, :state, "not_selected"))
        ~> selections

        tournament
        |> Map.put(:team, team)
        |> Map.put(:map, selections)
        ~> tournament

        render(conn, "tournament_info.json", tournament: tournament)

      {:ok, %TournamentLog{} = tournament_log} ->
        unless is_nil(user_id) do
          user_id = Tools.to_integer_as_needed(user_id)

          Accounts.gain_score(%{"user_id" => user_id, "game_name" => tournament_log.game_name, "score" => 1})
        end

        entrants = Log.get_entrant_logs_by_tournament_id(tournament_log.tournament_id)
        tournament_log = Map.put(tournament_log, :entrants, entrants)

        render(conn, "tournament_log.json", tournament_log: tournament_log)

      _ ->
        render(conn, "error.json", error: nil)
    end
  end
  def show(conn, %{"tournament_id" => tournament_id}) do
    show(conn, %{"user_id" => nil, "tournament_id" => tournament_id})
  end

  # TODO: web版で必要になっているから置いてあるが、必要なくなったら消す
  @doc """
  Get a thumbnail image of a tournament.
  """
  def get_thumbnail_image(conn, %{"thumbnail_path" => path}) do
    case Application.get_env(:milk, :environment) do
      :test -> read_thumbnail(path)
      # coveralls-ignore-start
      :dev -> read_thumbnail(path)
      _ -> read_thumbnail_prod(path)
      # coveralls-ignore-stop
    end
    ~> map

    json(conn, map)
  end

  @doc """
  Get a thumbnail image of a tournament by tournament id.
  """
  def get_thumbnail_by_tournament_id(conn, %{"tournament_id" => id}) do
    case Tournaments.load_tournament(id) do
      nil ->
        json(conn, %{result: false})

      tournament ->
        path = tournament.thumbnail_path

        map =
          case Application.get_env(:milk, :environment) do
            :test ->
              read_thumbnail(path)

            # coveralls-ignore-start
            :dev ->
              read_thumbnail(path)

            _ ->
              read_thumbnail_prod(path)
              # coveralls-ignore-stop
          end

        json(conn, %{result: true, b64: map.b64})
    end
  end

  defp read_thumbnail(path) do
    path
    |> File.read()
    |> case do
      {:ok, file} ->
        b64 = Base.encode64(file)
        %{b64: b64}

      {:error, _} ->
        %{error: "image not found"}
    end
  end

  #  coveralls-ignore-start
  defp read_thumbnail_prod(path) do
    {:ok, object} = Objects.get(path)
    {:ok, file} = Image.get(object.mediaLink)
    b64 = Base.encode64(file)
    %{b64: b64}
  end

  # coveralls-ignore-stop

  @doc """
  Gets tournament info list for home screen.
  """
  def home(conn, %{"user_id" => user_id, "date_offset" => date_offset, "offset" => offset}) do
    user_id = Tools.to_integer_as_needed(user_id)
    offset = Tools.to_integer_as_needed(offset)

    date_offset
    |> Tournaments.home_tournament(offset, user_id)
    |> do_home()
    ~> tournaments

    render(conn, "home.json", tournaments_info: tournaments)
  end

  def home(conn, %{"date_offset" => date_offset, "offset" => offset}) do
    offset = Tools.to_integer_as_needed(offset)

    date_offset
    |> Tournaments.home_tournament(offset)
    |> do_home()
    ~> tournaments

    render(conn, "home.json", tournaments_info: tournaments)
  end

  def home(conn, %{"filter" => filter, "user_id" => user_id}) do
    user_id
    |> Tools.to_integer_as_needed()
    |> load_filtered_home(filter)
    |> do_home()
    ~> tournaments

    render(conn, "home.json", tournaments_info: tournaments)
  end

  @spec do_home([Tournament.t()]) :: [Tournament.t()]
  defp do_home(tournaments) do
    tournaments
    |> Enum.map(fn tournament ->
      tournament.id
      |> Tournaments.get_entrants()
      |> Enum.map(&Accounts.get_user(&1.user_id))
      ~> entrants

      Map.put(tournament, :entrants, entrants)
    end)
    |> Enum.map(fn tournament ->
      teams = Tournaments.get_confirmed_teams(tournament.id)
      Map.put(tournament, :teams, teams)
    end)
  end

  defp load_filtered_home(user_id, "fav"), do: Tournaments.home_tournament_fav(user_id)
  defp load_filtered_home(user_id, "plan"), do: Tournaments.home_tournament_plan(user_id)

  defp load_filtered_home(user_id, "entry"),
    do: Tournaments.get_participating_tournaments(user_id)

  @doc """
  Get searched tournaments as home.
  """
  def search(conn, %{"user_id" => user_id, "text" => text}) do
    user_id
    |> Tournaments.search(text)
    |> do_home()
    ~> tournaments

    render(conn, "home.json", tournaments_info: tournaments)
  end

  @doc """
  Update a tournament.
  """
  def update(conn, %{"tournament_id" => id, "tournament" => tournament_params}) do
    tournament = Tournaments.load_tournament(id)

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

      tournament
      |> Tournaments.update_tournament(tournament_params)
      |> case do
        {:ok, %Tournament{} = tournament} ->
          update_queue_tournament_start_push_notice(tournament)
          render(conn, "show.json", tournament: tournament)

        {:error, error} ->
          render(conn, "error.json", error: error)
      end
    else
      render(conn, "error.json", error: nil)
    end
  end

  @doc """
  Deletes a tournament.
  """
  def delete(conn, %{"tournament_id" => tournament_id}) do
    tournament_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.load_tournament()
    |> Tournaments.delete_tournament()
    |> case do
      {:ok, %Tournament{} = tournament} ->
        notify_discord_on_deleting_tournament_as_needed(tournament)
        json(conn, %{result: true})

      {:error, error} ->
        render(conn, "error.json", error: error)
    end
  end

  defp notify_discord_on_deleting_tournament_as_needed(%Tournament{discord_server_id: nil}), do: {:ok, nil}
  defp notify_discord_on_deleting_tournament_as_needed(%Tournament{discord_server_id: discord_server_id}) do
    # NOTE: discordサーバーが起動していない場合はここがタイムアウトの原因となる
    Discord.send_tournament_delete_notification(discord_server_id)
    {:ok, nil}
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
    offset = Tools.to_integer_as_needed(offset)

    user_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.get_participating_tournaments(offset)
    |> do_home()
    ~> tournaments
    |> Enum.empty?()
    |> if do
      render(conn, "error.json", error: nil)
    else
      render(conn, "home.json", tournaments_info: tournaments)
    end
  end

  def participating_tournaments(conn, %{"user_id" => user_id}) do
    user_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.get_participating_tournaments()
    |> do_home()
    ~> tournaments
    |> Enum.empty?()
    |> if do
      render(conn, "error.json", error: nil)
    else
      render(conn, "home.json", tournaments_info: tournaments)
    end
  end

  @doc """
  Get relevant tournaments.
  """
  def relevant(conn, %{"user_id" => user_id}) do
    user_id
    |> Tools.to_integer_as_needed()
    |> do_relevant()
    ~> tournaments

    render(conn, "index.json", tournament: tournaments)
  end

  @spec do_relevant(integer()) :: [Tournament.t()]
  defp do_relevant(user_id) do
    participatings = Tournaments.get_participating_tournaments(user_id)
    hostings = Tournaments.get_tournaments_by_master_id(user_id)

    user_id
    |> Tournaments.get_assistants_by_user_id()
    |> Enum.map(&Tournaments.load_tournament(&1.tournament_id))
    ~> assistants

    tournaments = participatings ++ hostings ++ assistants

    Enum.uniq(tournaments)
  end

  @doc """
  Get pending tournaments.
  """
  def pending(conn, %{"user_id" => user_id}) do
    user_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.get_pending_tournaments()
    ~> tournaments

    render(conn, "index.json", tournament: tournaments)
  end

  @doc """
  Check whether the user can join the tournament.
  大会キャパシティチェック
  ユーザーの参加している他の大会との時間帯チェック
  """
  def is_able_to_join(conn, %{"user_id" => user_id, "tournament_id" => tournament_id}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    user_id = Tools.to_integer_as_needed(user_id)

    tournament = Tournaments.load_tournament(tournament_id)
    entrants = Tournaments.get_entrants(tournament_id)
    result = true

    result
    |> is_valid_deadline?(tournament)
    |> is_valid_capacity?(tournament, entrants)
    |> already_participated?(entrants, user_id)
    |> already_participated_as_team?(tournament, user_id)
    |> is_valid_event_date?(tournament, user_id)
    ~> result

    requested? = Tournaments.has_requested_as_team?(user_id, tournament_id)
    confirmed? = Tournaments.has_confirmed_as_team?(user_id, tournament_id)

    json(conn, %{
      result: result,
      has_requested_as_team: requested?,
      has_confirmed_as_team: confirmed?
    })
  end

  defp is_valid_deadline?(result, %Tournament{deadline: deadline}) do
    deadline
    |> Milk.EctoDate.dump()
    |> elem(1)
    |> DateTime.compare(Timex.now())
    |> Kernel.!=(:lt)
    |> Kernel.and(result)
  end

  defp is_valid_capacity?(result, %Tournament{is_team: true, capacity: capacity, team: teams}, _) do
    capacity
    |> Kernel.>(length(teams))
    |> Kernel.and(result)
  end
  defp is_valid_capacity?(result, %Tournament{capacity: capacity}, entrants) do
    capacity
    |> Kernel.>(length(entrants))
    |> Kernel.and(result)
  end

  defp already_participated?(result, entrants, user_id) do
    entrants
    |> Enum.all?(&(&1.user_id != user_id))
    |> Kernel.and(result)
  end

  defp already_participated_as_team?(result, %Tournament{id: id}, user_id) do
    user_id
    |> Tournaments.has_requested_as_team?(id)
    |> Kernel.not()
    |> Kernel.and(result)
  end

  defp is_valid_event_date?(result, %Tournament{master_id: master_id, event_date: event_date}, user_id) do
    user_id
    |> do_relevant()
    |> Enum.all?(fn tournament ->
      master_id == user_id || tournament.event_date != event_date || is_nil(tournament.event_date)
    end)
    |> Kernel.and(result)
  end

  @doc """
  Checks if the user is related to a started tournament.
  """
  def is_started_at_least_one(conn, %{"user_id" => user_id}) do
    user_id
    |> Tools.to_integer_as_needed()
    |> do_relevant()
    |> Enum.filter(fn tournament ->
      tournament.is_started
    end)
    ~> tournaments

    render(conn, "tournament_result.json", tournament: List.first(tournaments))
  end

  @doc """
  Get tournament topics.
  """
  def tournament_topics(conn, %{"tournament_id" => tournament_id, "user_id" => user_id}) do
    tournament_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.get_tabs_including_logs_by_tourament_id()
    |> Enum.map(fn tab ->
      chat_room = Chat.get_chat_room(tab.chat_room_id)
      member = Chat.get_member(chat_room.id, user_id)

      tab
      |> Map.put(:authority, chat_room.authority)
      |> Map.put(:can_speak, chat_room.authority <= member.authority)
    end)
    ~> tabs

    render(conn, "tournament_topics.json", topics: tabs)
  end

  @doc """
  Update tournament topics.
  """
  def tournament_update_topics(conn, %{"tournament_id" => tournament_id, "tabs" => tabs}) do
    tournament = Tournaments.load_tournament(tournament_id)

    if tournament do
      current_tabs = Tournaments.get_tabs_including_logs_by_tourament_id(tournament_id)
      Tournaments.update_topic(tournament, current_tabs, tabs)

      tabs =
        tournament_id
        |> Tournaments.get_tabs_including_logs_by_tourament_id()
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
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    with %Tournament{is_started: false} = tournament     <- Tournaments.load_tournament(tournament_id),
         true                                            <- validate_master_id?(tournament, master_id),
         {:ok, match_list, match_list_with_fight_result} <- do_start(tournament),
         user_id_list                                    <- Tournaments.all_relevant_user_id_list(tournament_id) do
      render(conn, "start.json", %{match_list: match_list, match_list_with_fight_result: match_list_with_fight_result, user_id_list: user_id_list})
    else
      %Tournament{is_started: true} -> render(conn, "error.json", error: "Tournament has already been started.")
      false                         -> render(conn, "error.json", error: "invalid master id")
      {:error, error, nil}          -> render(conn, "error.json", error: Tools.create_error_message(error))
    end
  end

  defp validate_master_id?(%Tournament{master_id: mid}, master_id), do: master_id == mid

  defp do_start(%Tournament{is_team: true, master_id: master_id} = tournament) do
    start_team_tournament(master_id, tournament)
  end
  defp do_start(%Tournament{is_team: false, master_id: master_id} = tournament) do
    start_tournament(master_id, tournament)
  end

  defp start_team_tournament(master_id, tournament) do
    case tournament.type do
      2 -> Progress.start_team_best_of_format(master_id, tournament)
      _ -> {:error, "unsupported tournament type", nil}
    end
  end

  defp start_tournament(master_id, tournament) do
    case tournament.type do
      1 -> Progress.start_single_elimination(master_id, tournament)
      2 -> Progress.start_best_of_format(master_id, tournament)
      _ -> {:error, "unsupported tournament type", nil}
    end
  end

  @doc """
  Delete losers of a loser list.
  """
  def delete_loser(conn, %{"tournament" => %{"tournament_id" => tournament_id, "loser_list" => loser}}) when is_binary(loser) or is_integer(loser) do
    delete_loser(conn, %{"tournament" => %{"tournament_id" => tournament_id, "loser_list" => [loser]}})
  end

  def delete_loser(conn, %{"tournament" => %{"tournament_id" => tournament_id, "loser_list" => loser_list}}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    loser_list = Enum.map(loser_list, &Tools.to_integer_as_needed(&1))

    tournament_id
    |> Tournaments.load_tournament()
    |> then(fn tournament ->
      if tournament.type == 1 do
        store_single_tournament_match_log(tournament_id, hd(loser_list))
      end
    end)

    tournament_id
    |> Tournaments.delete_loser_process(loser_list)
    |> case do
      {:ok, match_list} -> render(conn, "loser.json", list: match_list)
      {:error, error} -> render(conn, "error.json", error: error)
    end
  end

  defp store_single_tournament_match_log(tournament_id, loser_list) when is_list(loser_list) do
    store_single_tournament_match_log(tournament_id, hd(loser_list))
  end

  defp store_single_tournament_match_log(tournament_id, loser_id) when is_integer(loser_id) do
    tournament_id
    |> Progress.get_match_list()
    |> inspect(charlists: false)
    ~> match_list_str

    {:ok, winner} = Tournaments.get_opponent(tournament_id, loser_id)

    Map.new()
    |> Map.put("tournament_id", tournament_id)
    |> Map.put("loser_id", loser_id)
    |> Map.put("winner_id", winner.id)
    |> Map.put("match_list_str", match_list_str)
    |> Progress.create_single_tournament_match_log()
  end

  @doc """
  Find a match of a specific tournament.
  """
  def find_match(conn, %{"tournament_id" => tournament_id, "user_id" => user_id}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    user_id = Tools.to_integer_as_needed(user_id)

    case Progress.get_match_list(tournament_id) do
      [] ->
        json(conn, %{result: false, match: nil})

      match_list when is_list(match_list) ->
        match = Tournaments.find_match(match_list, user_id)
        result = Tournaments.is_alone?(match)

        json(conn, %{result: result, match: match})
    end
  end

  @doc """
  Get a match list of a tournament.
  """
  def get_match_list(conn, %{"tournament_id" => tournament_id}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    match_list = Progress.get_match_list(tournament_id)

    if match_list == [] do
      json(conn, %{match_list: nil, result: false})
    else
      json(conn, %{match_list: match_list, result: true})
    end
  end

  @doc """
  Get options by tournament id.
  """
  def maps(conn, %{"tournament_id" => tournament_id, "user_id" => user_id}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    user_id = Tools.to_integer_as_needed(user_id)

    maps = Tournaments.get_selectable_maps_by_tournament_id_and_user_id(tournament_id, user_id)

    render(conn, "maps.json", maps: maps)
  end

  def maps(conn, %{"tournament_id" => tournament_id}) do
    tournament_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.get_maps_by_tournament_id()
    |> Enum.map(&Map.put(&1, :state, "not_selected"))
    ~> maps

    render(conn, "maps.json", maps: maps)
  end

  @doc """
  Get icon of an option.
  """
  def get_map_icon(conn, %{"path" => path}) do
    :milk
    |> Application.get_env(:environment)
    |> case do
      :dev -> Image.read_image(path)
      :test -> Image.read_image(path)
      _ -> Image.read_image_prod(path)
    end
    |> case do
      {:ok, image} ->
        b64 = Base.encode64(image)
        json(conn, %{b64: b64})

      {:error, error} ->
        render(conn, "error.json", error: error)
    end
  end

  @doc """
  Ban maps.
  """
  def ban_maps(conn, %{"user_id" => user_id, "tournament_id" => tournament_id, "map_id_list" => map_id_list}) do
    user_id = Tools.to_integer_as_needed(user_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    map_id_list = Enum.map(map_id_list, &Tools.to_integer_as_needed(&1))

    with {:ok, tournament} <- Tournaments.ban_maps(user_id, tournament_id, map_id_list),
         {:ok, _}          <- notify_discord_on_ban_maps_as_needed!(user_id, tournament, map_id_list),
         messages          <- Tournaments.all_states!(tournament_id) do
      render(conn, "interaction_message.json", interaction_messages: messages, rule: tournament.rule)
    else
      {:error, error} -> render(conn, "error.json", error: error)
      _               -> render(conn, "error.json", error: nil)
    end
  end

  defp notify_discord_on_ban_maps_as_needed!(_, %Tournament{discord_server_id: nil}, _), do: {:ok, nil}
  defp notify_discord_on_ban_maps_as_needed!(user_id, %Tournament{id: tournament_id, discord_server_id: discord_server_id, is_team: is_team}, map_id_list) do
    {:ok, opponent} = Tournaments.get_opponent(tournament_id, user_id)

    if is_team do
      team = Tournaments.get_team_by_tournament_id_and_user_id(tournament_id, user_id)
      team.name
    else
      user = Accounts.get_user(user_id)
      user.name
    end
    ~> name

    map_id_list
    |> Enum.map(fn map_id ->
      map_id
      |> Tournaments.get_map()
      |> Map.get(:name)
    end)
    ~> banned_map_names

    Discord.send_tournament_ban_map_notification(
      discord_server_id,
      name,
      opponent.name,
      banned_map_names
    )
  end

  @doc """
  Choose a map.
  """
  def choose_map(conn, %{"user_id" => user_id, "tournament_id" => tournament_id, "map_id" => map_id}) do
    user_id = Tools.to_integer_as_needed(user_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    map_id = Tools.to_integer_as_needed(map_id)

    with {:ok, tournament} <- Tournaments.choose_maps(user_id, tournament_id, [map_id]),
         {:ok, _}          <- notify_discord_on_choose_map_as_needed!(user_id, tournament, map_id),
         messages          <- Tournaments.all_states!(tournament_id) do
      render(conn, "interaction_message.json", interaction_messages: messages, rule: tournament.rule)
    else
      {:error, error} -> render(conn, "error.json", error: error)
      _               -> render(conn, "error.json", error: nil)
    end
  end

  defp notify_discord_on_choose_map_as_needed!(_, %Tournament{discord_server_id: nil}, _), do: {:ok, nil}
  defp notify_discord_on_choose_map_as_needed!(user_id, %Tournament{id: tournament_id, discord_server_id: discord_server_id, is_team: is_team}, map_id) do
    {:ok, opponent} = Tournaments.get_opponent(tournament_id, user_id)

    if is_team do
      team = Tournaments.get_team_by_tournament_id_and_user_id(tournament_id, user_id)
      team.name
    else
      user = Accounts.get_user(user_id)
      user.name
    end
    ~> name

    map_name = Tournaments.get_map(map_id).name

    Discord.send_tournament_choose_map_notification(discord_server_id, name, opponent.name, map_name)
  end

  @doc """
  Choose a map.
  """
  def choose_ad(conn, %{"user_id" => user_id, "tournament_id" => tournament_id, "is_attacker_side" => is_attacker_side}) do
    user_id = Tools.to_integer_as_needed(user_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    is_attacker_side = is_attacker_side == "1" || is_attacker_side == true || is_attacker_side == "true"

    with {:ok, tournament} <- Tournaments.choose_ad(user_id, tournament_id, is_attacker_side),
         {:ok, _}          <- notify_discord_on_choose_ad_as_needed!(user_id, tournament, is_attacker_side),
         messages          <- Tournaments.all_states!(tournament_id) do
      render(conn, "interaction_message.json", interaction_messages: messages, rule: tournament.rule)
    else
      {:error, error} -> render(conn, "error.json", error: error)
      _               -> render(conn, "error.json", error: nil)
    end
  end

  defp notify_discord_on_choose_ad_as_needed!(_, %Tournament{discord_server_id: nil}, _), do: {:ok, nil}
  defp notify_discord_on_choose_ad_as_needed!(user_id, %Tournament{id: tournament_id, discord_server_id: discord_server_id, is_team: is_team}, is_attacker_side) do
    {:ok, opponent} = Tournaments.get_opponent(tournament_id, user_id)

    if is_team do
      team = Tournaments.get_team_by_tournament_id_and_user_id(tournament_id, user_id)
      team.name
    else
      user = Accounts.get_user(user_id)
      user.name
    end
    ~> name

    Discord.send_tournament_choose_ad_notification(
      discord_server_id,
      name,
      opponent.name,
      is_attacker_side
    )
  end

  @doc """
  Start a single match in the tournament.
  """
  def start_match(conn, %{"user_id" => user_id, "tournament_id" => tournament_id}) do
    user_id = Tools.to_integer_as_needed(user_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    tournament = Tournaments.load_tournament(tournament_id)

    with {:ok, _}   <- Tournaments.start_match(tournament, user_id),
         {:ok, _}   <- do_start_match(tournament, user_id),
         {:ok, _}   <- Tournaments.break_waiting_state_as_needed(tournament, user_id),
         {:ok, nil} <- notify_discord_on_start_match_as_needed(tournament, user_id),
         messages   <- Tournaments.all_states!(tournament_id) do
      render(conn, "interaction_message.json", interaction_messages: messages, rule: tournament.rule)
    else
      _ -> render(conn, "error.json", error: nil)
    end
  end

  @spec do_start_match(Tournament.t() | nil, integer()) :: {:ok, nil} | {:error, String.t()}
  defp do_start_match(%Tournament{is_team: true} = tournament, user_id) do
    if start_team_match(tournament, user_id) do
      {:ok, nil}
    else
      {:error, "failed to start team match"}
    end
  end
  defp do_start_match(%Tournament{id: id}, user_id) do
    if start_individual_match(id, user_id) do
      {:ok, nil}
    else
      {:error, "failed to start individual match"}
    end
  end

  @spec start_individual_match(integer(), integer()) :: boolean()
  defp start_individual_match(tournament_id, user_id) do
    user_id
    |> Progress.get_match_pending_list(tournament_id)
    |> insert_match_pending_list_as_needed?(user_id, tournament_id)
  end

  @spec insert_match_pending_list_as_needed?(any(), integer(), integer()) :: boolean()
  defp insert_match_pending_list_as_needed?(nil, id, tournament_id), do: Progress.insert_match_pending_list_table(id, tournament_id)
  defp insert_match_pending_list_as_needed?(_, _, _), do: false

  @spec start_team_match(Tournament.t(), integer()) :: boolean()
  defp start_team_match(%Tournament{id: id}, user_id) do
    id
    |> Tournaments.get_team_by_tournament_id_and_user_id(user_id)
    |> Map.get(:id)
    ~> team_id
    |> Progress.get_match_pending_list(id)
    |> case do
      nil ->
        team_id
        |> Progress.insert_match_pending_list_table(id)
        |> case do
          {:ok, _}    -> true
          {:error, _} -> false
        end
      _ ->
        true
    end
  end

  defp notify_discord_on_start_match_as_needed(%Tournament{discord_server_id: nil}, _), do: {:ok, nil}
  defp notify_discord_on_start_match_as_needed(%Tournament{id: id} = tournament, user_id) do
    with {:ok, opponent} <- Tournaments.get_opponent(id, user_id),
         {:ok, id, name} <- load_necessary_tournament_info(tournament, user_id),
         {:ok, nil} <- do_notify_discord_on_start_match_as_needed(tournament, id, opponent.id, name, opponent.name) do
      {:ok, nil}
    else
      error -> error
    end
  end

  @spec load_necessary_tournament_info(Tournament.t() | nil, integer()) :: {:ok, integer(), String.t()} | {:error, String.t()}
  defp load_necessary_tournament_info(%Tournament{id: id, is_team: is_team}, user_id) when is_team == true do
    id
    |> Tournaments.get_team_by_tournament_id_and_user_id(user_id)
    |> load_necessary_team_tournament_info()
  end
  defp load_necessary_tournament_info(_, user_id) do
    user = Accounts.get_user(user_id)
    {:ok, user.id, user.name}
  end

  defp load_necessary_team_tournament_info(nil), do: {:error, "team is nil"}
  defp load_necessary_team_tournament_info(%Team{id: id, name: name}), do: {:ok, id, name}

  @spec do_notify_discord_on_start_match_as_needed(Tournament.t(), integer(), integer(), String.t(), String.t()) :: {:ok, nil}
  defp do_notify_discord_on_start_match_as_needed(%Tournament{id: tournament_id, discord_server_id: discord_server_id}, id, opponent_id, name, opponent_name) do
    pending_list = Progress.get_match_pending_list(id, tournament_id)
    opponent_pending_list = Progress.get_match_pending_list(opponent_id, tournament_id)

    if pending_list != [] && opponent_pending_list != [] do
      Discord.send_tournament_start_match_notification(discord_server_id, name, opponent_name)
    end

    {:ok, nil}
  end

  @doc """
  Get an opponent of a tournament match.
  """
  def get_opponent(conn, %{"tournament_id" => tournament_id, "user_id" => user_id}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    user_id = Tools.to_integer_as_needed(user_id)

    tournament_id
    |> Progress.get_match_list()
    |> do_get_opponent(tournament_id, user_id)
    |> case do
      {:ok, opponent} -> render(conn, "opponent.json", opponent: opponent)
      {:wait, _} -> json(conn, %{result: false, opponent: nil, wait: true})
      {:error, "match list is integer"} -> json(conn, %{result: false})
      _ -> render(conn, "error.json", error: nil)
    end
  end

  def get_opponent(conn, %{"tournament_id" => tournament_id, "team_id" => team_id}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    team_id = Tools.to_integer_as_needed(team_id)

    tournament_id
    |> Progress.get_match_list()
    |> do_get_team_opponent(tournament_id, team_id)
    |> case do
      {:ok, opponent} ->
        opponent.id
        |> Tournaments.get_leader()
        |> Map.get(:user)
        ~> leader

        render(conn, "opponent_team.json", opponent: opponent, leader: leader)

      {:wait, nil} ->
        json(conn, %{result: false, opponent: nil, wait: true})
      {:error, "match list is integer"} ->
        json(conn, %{result: false})
      _ ->
        render(conn, "error.json", error: nil)
    end
  end

  defp do_get_opponent(match_list, _, _) when is_integer(match_list), do: {:error, "match list is integer"}
  defp do_get_opponent(_, tournament_id, user_id), do: Tournaments.get_opponent(tournament_id, user_id)

  defp do_get_team_opponent(match_list, _, _) when is_integer(match_list), do: {:error, "match list is integer"}
  defp do_get_team_opponent(_, tournament_id, team_id) do
    team_id
    |> Tournaments.get_leader()
    |> Map.get(:user_id)
    ~> leader_id

    Tournaments.get_opponent(tournament_id, leader_id)
  end

  @doc """
  Get fighting users.
  """
  def get_fighting_users(conn, %{"tournament_id" => tournament_id}) do
    tournament_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.load_tournament()
    |> Map.get(:is_team)
    |> if do
      tournament_id
      |> Tools.to_integer_as_needed()
      |> Tournaments.get_fighting_users()
      |> case do
        [] -> json(conn, %{data: [], result: true})
        teams -> render(conn, "teams.json", teams: teams)
      end
    else
      tournament_id
      |> Tools.to_integer_as_needed()
      |> Tournaments.get_fighting_users()
      |> case do
        [] -> json(conn, %{data: [], result: true})
        users -> render(conn, "users.json", users: users)
      end
    end
  end

  @doc """
  Get waiting users for fighting ones.
  """
  def get_waiting_users(conn, %{"tournament_id" => tournament_id}) do
    tournament_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.load_tournament()
    |> Map.get(:is_team)
    |> if do
      tournament_id
      |> Tools.to_integer_as_needed()
      |> Tournaments.get_waiting_users()
      |> case do
        [] -> json(conn, %{data: [], result: true})
        teams -> render(conn, "teams.json", teams: teams)
      end
    else
      tournament_id
      |> Tools.to_integer_as_needed()
      |> Tournaments.get_waiting_users()
      |> case do
        [] -> json(conn, %{data: [], result: true})
        users -> render(conn, "users.json", users: users)
      end
    end
  end

  @doc """
  Check if the user has already matching.
  """
  def check_pending(conn, %{"user_id" => user_id, "tournament_id" => tournament_id}) do
    user_id = Tools.to_integer_as_needed(user_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    state = Progress.get_match_pending_list(user_id, tournament_id)

    if is_nil(state) do
      json(conn, %{result: false})
    else
      json(conn, %{result: true, tournament_id: tournament_id})
    end
  end

  @doc """
  Check if the user has already lost.
  """
  def has_lost?(conn, %{"user_id" => user_id, "tournament_id" => tournament_id}) do
    user_id = Tools.to_integer_as_needed(user_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    match_list = Progress.get_match_list(tournament_id)

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

    score =
      if state == "IsPending" do
        tournament_id
        |> Progress.get_score(user_id)
        |> case do
          nil -> nil
          score -> score
        end
      end

    json(conn, %{result: true, state: state, score: score})
  end

  @doc """
  Claim win of the user.
  """
  def claim_win(conn, %{"user_id" => user_id, "tournament_id" => tournament_id}) do
    user_id = Tools.to_integer_as_needed(user_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    tournament_id
    |> Tournaments.load_tournament()
    |> Map.get(:rule)
    |> Tournaments.rule_needs_score?()
    |> if do
      json(conn, %{result: true, error: "Should provide score in the tournament rule"})
    else
      tournament = Tournaments.load_tournament(tournament_id)
      do_claim_score(conn, user_id, tournament, 1)
    end
  end

  @doc """
  Claim lose of the user.
  """
  def claim_lose(conn, %{"user_id" => user_id, "tournament_id" => tournament_id}) do
    user_id = Tools.to_integer_as_needed(user_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    tournament_id
    |> Tournaments.load_tournament()
    |> Map.get(:rule)
    |> Tournaments.rule_needs_score?()
    |> if do
      json(conn, %{result: true, error: "Should provide score in the tournament rule"})
    else
      tournament = Tournaments.load_tournament(tournament_id)
      do_claim_score(conn, user_id, tournament, 0)
    end
  end


  @doc """
  Claims score

  1. スコアをredisに登録する
  2. 相手もスコアを登録していたらマッチが進む
  """
  def claim_score(conn, %{"tournament_id" => tournament_id, "user_id" => user_id, "score" => score, "match_index" => match_index}) do
    user_id = Tools.to_integer_as_needed(user_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    score = Tools.to_integer_as_needed(score)
    match_index = Tools.to_integer_as_needed(match_index)

    tournament = Tournaments.load_tournament(tournament_id)
    do_claim_score(conn, user_id, tournament, score, match_index)
  end

  # bodyless clause
  defp do_claim_score(conn, user_id, tournament, score, match_index \\ 0)
  defp do_claim_score(conn, _,       nil,        _,     _),          do: render(conn, "error.json", error: "tournament is nil")
  defp do_claim_score(conn, user_id, tournament, score, match_index) do
    # NOTE: あとでtournament変数はシャドウイングするので必要な情報だけ退避しておく
    tournament_id = tournament.id
    rule = tournament.rule
    with true                                           <- claimable_state?(tournament_id, user_id),
         id             when not is_nil(id)             <- Progress.get_necessary_id(tournament_id, user_id),
         {:ok, opponent}                                <- Tournaments.get_opponent(tournament_id, user_id),
         {:ok, _}                                       <- Progress.insert_score(tournament_id, id, score),
         opponent_score when not is_nil(opponent_score) <- Progress.get_score(tournament_id, opponent.id),
         {:ok, winner_id, loser_id, _}                  <- calculate_winner(id, opponent.id, score, opponent_score),
         {:ok, nil}                                     <- proceed_to_next_match(tournament, winner_id, loser_id, score, opponent_score, match_index),
         tournament                                     <- Tournaments.load_tournament(tournament_id) do
      # TODO: このall_statesの大会終了後処理
      messages = Tournaments.all_states!(tournament_id)
      claim = %Claim{
        validated: true,
        completed: true,
        is_finished: is_nil(tournament),
        interaction_messages: messages,
        rule: rule
      }
      render(conn, "claim.json", claim: claim)
    else
      # NOTE: 重複報告が起きたときの処理
      {:error, id, opponent_id, _} ->
        duplicated_claim_process(tournament.id, id, opponent_id, score)
        claim = %Claim{
          validated:   false,
          completed:   false,
          is_finished: false,
          interaction_messages: [],
          rule: rule
        }
        render(conn, "claim.json", claim: claim)
      nil ->
        claim = %Claim{
          validated:   true,
          completed:   false,
          is_finished: false,
          interaction_messages: [],
          rule: rule
        }
        render(conn, "claim.json", claim: claim)
      false ->
        render(conn, "error.json", error: "Invalid state")
      _ ->
        claim = %Claim{
          validated:   false,
          completed:   false,
          is_finished: false,
          interaction_messages: [],
          rule: rule
        }
        render(conn, "claim.json", claim: claim)
    end
  end

  @spec claimable_state?(integer(), integer()) :: boolean()
  defp claimable_state?(tournament_id, user_id) do
    Tournaments.state!(tournament_id, user_id) == "IsPending"
  end

  @spec duplicated_claim_process(integer(), integer(), integer(), integer()) :: {:ok, nil} | {:error, String.t()}
  defp duplicated_claim_process(tournament_id, id, opponent_id, score) do
    with {:ok, nil} <- Progress.add_duplicate_user_id(tournament_id, id),
         {:ok, nil} <- Progress.add_duplicate_user_id(tournament_id, opponent_id),
         {:ok, nil} <- notify_discord_on_duplicate_claim_as_needed(tournament_id, id, opponent_id, score),
         {:ok, nil} <- notify_on_duplicate_match(tournament_id, id, opponent_id) do
      {:ok, nil}
    else
      error -> error
    end
  end

  @spec calculate_winner(integer(), integer(), integer(), integer()) :: {:ok, integer(), integer(), boolean()} | {:error, integer(), integer(), boolean()}
  defp calculate_winner(id1, id2, score1, score2) when score1 == score2, do: {:error, id1, id2, false}
  defp calculate_winner(id1, id2, score1, score2) when score1 > score2,  do: {:ok, id1, id2, true}
  defp calculate_winner(id1, id2, score1, score2) when score1 < score2,  do: {:ok, id2, id1, true}

  # TODO: この辺の引数は使うものが決まっているので構造体の使用を検討
  # NOTE: この関数ではすでに勝敗が決定している前提で処理が進んでいく。
  @spec proceed_to_next_match(Tournament.t(), integer(), integer(), integer(), integer(), integer()) :: {:ok, nil} | {:error, String.t()}
  defp proceed_to_next_match(tournament, winner_id, loser_id, score, opponent_score, match_index) when is_integer(opponent_score) do
    with {:ok, nil} <- notify_discord_on_match_finished_as_needed(tournament, winner_id, loser_id, score, opponent_score),
         {:ok, _}   <- Tournaments.delete_loser_process(tournament.id, [loser_id]),
         {:ok, nil} <- Tournaments.store_score(tournament.id, winner_id, loser_id, opponent_score, score, match_index),
         {:ok, nil} <- delete_old_info_for_next_match(tournament.id, [winner_id, loser_id]),
         {:ok, _}   <- Tournaments.change_winner_state(tournament, winner_id),
         {:ok, _}   <- Tournaments.change_loser_state(tournament, loser_id),
         {:ok, nil} <- finish_as_needed?(tournament.id, winner_id) do
      {:ok, nil}
    else
      error -> error
    end
  end

  @spec delete_old_info_for_next_match(integer(), [integer()]) :: {:ok, nil} | {:error, String.t()}
  defp delete_old_info_for_next_match(tournament_id, id_list) do
    id_list
    |> Enum.map(fn id ->
      with {:ok, nil} <- Progress.delete_match_pending_list(id, tournament_id),
           {:ok, nil} <- Progress.delete_score(tournament_id, id),
           {:ok, nil} <- Progress.delete_duplicate_users_all(tournament_id),
           {:ok, _}   <- Tournaments.delete_map_selections(tournament_id, id),
           {:ok, nil} <- Progress.delete_is_attacker_side(id, tournament_id),
           {:ok, nil} <- Progress.delete_ban_order(tournament_id, id) do
        {:ok, nil}
      else
        error -> error
      end
    end)
    |> Enum.all?(&match?({:ok, _}, &1))
    |> Tools.boolean_to_tuple("Failed to delete old info for next match")
  end

  @spec notify_discord_on_match_finished_as_needed(Tournament.t(), integer(), integer(), integer(), integer()) :: {:ok, nil} | {:error, String.t()}
  defp notify_discord_on_match_finished_as_needed(tournament, id, opponent_id, score, opponent_score) do
    with {:ok, opponent_name, name} <- load_names(tournament, id, opponent_id),
         {:ok, nil}                 <- send_tournament_finish_match_notification(tournament, name, opponent_name, score, opponent_score) do
      {:ok, nil}
    else
      error -> error
    end
  end

  @spec load_names(Tournament.t(), integer(), integer()) :: {:ok, String.t(), String.t()} | {:error, String.t()}
  defp load_names(%Tournament{is_team: true, id: tournament_id}, id, _) do
    with team   when not is_nil(team)   <- Tournaments.get_team(id),
         leader when not is_nil(leader) <- Tournaments.get_leader(team.id),
         {:ok, opponent}                <- Tournaments.get_opponent(tournament_id, leader.user_id) do
      {:ok, opponent.name, team.name}
    else
      nil          -> {:error, "team or leader is nil"}
      {:wait, nil} -> {:error, "opponent is nil"}
      error        -> error
    end
  end
  defp load_names(_, user_id, opponent_id) do
    user = Accounts.get_user(user_id)
    opponent = Accounts.get_user(opponent_id)

    {:ok, opponent.name, user.name}
  end

  defp send_tournament_finish_match_notification(%Tournament{discord_server_id: nil}, _, _, _, _), do: {:ok, nil}
  defp send_tournament_finish_match_notification(%Tournament{discord_server_id: discord_server_id}, name, opponent_name, score, opponent_score) do
    Discord.send_tournament_finish_match_notification(
      discord_server_id,
      name,
      opponent_name,
      score,
      opponent_score
    )
    {:ok, nil}
  end

  defp notify_discord_on_duplicate_claim_as_needed(tournament_id, id, opponent_id, score) do
    with tournament when not is_nil(tournament) <- Tournaments.load_tournament(tournament_id),
         {:ok, opponent_name, name}             <- load_necessary_opponent_info_on_notify_discord(tournament, id, opponent_id),
         {:ok, nil}                             <- do_notify_discord_on_duplicate_claim_as_needed(tournament, name, opponent_name, score) do
      {:ok, nil}
    else
      nil   -> {:error, "tournament is nil"}
      error -> error
    end
  end

  defp load_necessary_opponent_info_on_notify_discord(%Tournament{is_team: true, id: tournament_id}, team_id, _) do
    team = Tournaments.get_team(team_id)
    leader = Tournaments.get_leader(team.id)

    tournament_id
    |> Tournaments.get_opponent(leader.user_id)
    |> case do
      {:ok, opponent} -> {:ok, opponent.name, team.name}
      {:wait, nil}    -> raise "The given user should wait for the opponent."
      _               -> raise "Unknown error on claim score."
    end
  end
  defp load_necessary_opponent_info_on_notify_discord(_, user_id, opponent_id) do
    user = Accounts.get_user(user_id)
    opponent = Accounts.get_user(opponent_id)

    {:ok, opponent.name, user.name}
  end

  defp do_notify_discord_on_duplicate_claim_as_needed(%Tournament{discord_server_id: nil}, _, _, _), do: {:ok, nil}
  defp do_notify_discord_on_duplicate_claim_as_needed(%Tournament{discord_server_id: discord_server_id}, name, opponent_name, score) do
    Discord.send_tournament_duplicate_claim_notification(discord_server_id, name, opponent_name, score)
    {:ok, nil}
  end

  @doc """
  Flip Coin.
  """
  def flip_coin(conn, %{"tournament_id" => tournament_id, "user_id" => user_id}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    user_id = Tools.to_integer_as_needed(user_id)

    with tournament when not is_nil(tournament) <- Tournaments.load_tournament(tournament_id),
         {:ok, nil} <- Tournaments.flip_coin(user_id, tournament_id),
         {:ok, nil} <- Progress.insert_match_pending_list_table(user_id, tournament_id),
         {:ok, _}   <- Tournaments.break_waiting_state_as_needed(tournament, user_id),
         messages   <- Tournaments.all_states!(tournament_id) do
      render(conn, "interaction_message.json", interaction_messages: messages, rule: tournament.rule)
    else
      nil             -> render(conn, "error.json", error: "tournament is nil")
      {:error, error} -> render(conn, "error.json", error: error)
    end
  end

  # TODO: チーム対応
  # TODO: masterも通知対象に入れたい
  defp notify_on_duplicate_match(_tournament_id, user_id, opponent_id) do
    user = Accounts.get_user(user_id)
    opponent = Accounts.get_user(opponent_id)

    [user_id, opponent_id]
    |> Enum.map(fn user_id ->
      Accounts.get_devices_by_user_id(user_id)
    end)
    |> List.flatten()
    |> Enum.each(fn device ->
      body_text = "#{user.name}と#{opponent.name}の報告が同じスコアになってしまっています！"

      %{
        "title" => "重複した勝敗報告が起きています",
        "body_text" => body_text,
        "process_id" => "DUPLICATE_CLAIM",
        "user_id" => device.user_id,
        "data" => ""
      }
      |> Notif.create_notification()

      %Maps.PushIos{
        user_id: device.user_id,
        device_token: device.token,
        process_id: "DUPLICATRE_CLAIM",
        title: "重複した勝敗報告が起きています",
        message: body_text
      }
      |> Milk.Notif.push_ios()
    end)

    {:ok, nil}
  end

  @spec finish_as_needed?(integer(), integer()) :: {:ok, nil} | {:error, String.t()}
  defp finish_as_needed?(tournament_id, winner_id) do
    with match_list when is_integer(match_list) <- Progress.get_match_list(tournament_id),
         tournament when not is_nil(tournament) <- Tournaments.load_tournament(tournament_id),
         {:ok, nil} <- notify_discord_on_deleting_tournament_as_needed(tournament),
         {:ok, _}   <- Tournaments.finish(tournament_id, winner_id),
         {:ok, _}   <- create_match_list_with_fight_result_log_on_finish(tournament_id),
         {:ok, nil} <- Progress.delete_match_list(tournament_id),
         {:ok, nil} <- Progress.delete_match_list_with_fight_result(tournament_id),
         {:ok, nil} <- Progress.delete_match_pending_list_of_tournament(tournament_id),
         {:ok, nil} <- Progress.delete_fight_result_of_tournament(tournament_id),
         {:ok, nil} <- Progress.delete_duplicate_users_all(tournament_id) do
      {:ok, nil}
    else
      nil                                 -> {:error, "match list or tournament is nil"}
      match_list when is_list(match_list) -> {:ok, nil}
      {:error, message}                   -> {:error, message}
      _                                   -> {:error, "unexpected error"}
    end
  end

  defp create_match_list_with_fight_result_log_on_finish(tournament_id) do
    tournament_id
    |> Progress.get_match_list_with_fight_result()
    |> inspect(charlists: false)
    |> then(&(%{"tournament_id" => tournament_id, "match_list_with_fight_result_str" => &1}))
    |> Progress.create_match_list_with_fight_result_log()
  end

  @doc """
  Force to defeat a user.
  """
  def force_to_defeat(conn, %{"tournament_id" => tournament_id, "target_user_id" => target_user_id}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    target_user_id = Tools.to_integer_as_needed(target_user_id)

    tournament_id
    |> Tournaments.get_opponent(target_user_id)
    |> case do
      {:ok, winner} ->
        Tournaments.promote_rank(%{"tournament_id" => tournament_id, "user_id" => winner.id})
        Tournaments.store_score(tournament_id, winner.id, target_user_id, 0, -1, 0)
        Tournaments.delete_loser_process(tournament_id, [target_user_id])
        finish_as_needed?(tournament_id, winner.id)

      {:wait, nil} ->
        tournament_id
        |> Progress.get_match_list()
        |> Tournaments.find_match(target_user_id)
        |> Kernel.--([target_user_id])
        |> hd()
        |> Enum.each(fn user_id ->
          Tournaments.force_to_promote_rank(%{
            "tournament_id" => tournament_id,
            "user_id" => user_id
          })
        end)

        Tournaments.delete_loser_process(tournament_id, [target_user_id])
    end

    json(conn, %{result: true})
  end

  @doc """
  Get a tournament by url.
  """
  def get_tournament_by_url(conn, %{"url" => url}) do
    url
    |> String.split("/")
    |> Enum.reverse()
    |> hd()
    ~> token

    tournament = Tournaments.get_tournament_by_url_token(token)
    team = Enum.filter(tournament.team, &(&1.is_confirmed))

    tournament.id
    |> Tournaments.get_maps_by_tournament_id()
    |> Enum.map(&Map.put(&1, :state, "not_selected"))
    ~> selections

    tournament
    |> Map.put(:team, team)
    |> Map.put(:map, selections)
    ~> tournament

    render(conn, "tournament_info.json", tournament: tournament)
  end

  @doc """
  Get a result of fight.
  """
  @spec is_user_win(Plug.Conn.t(), map) :: Plug.Conn.t()
  def is_user_win(conn, %{"user_id" => user_id, "tournament_id" => tournament_id}) do
    user_id = Tools.to_integer_as_needed(user_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    case Progress.get_score(tournament_id, user_id) do
      nil -> json(conn, %{is_win: nil, is_claimed: false})
      0 -> json(conn, %{is_win: false, tournament_id: tournament_id, is_claimed: true})
      1 -> json(conn, %{is_win: true, tournament_id: tournament_id, is_claimed: true})
      _ -> json(conn, %{is_win: nil, tournament_id: tournament_id, is_claimed: true})
    end
  end

  @doc """
  Get score of a user.
  """
  def score(conn, %{"tournament_id" => tournament_id, "user_id" => user_id}) do
    user_id = Tools.to_integer_as_needed(user_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    tournament_id
    |> Progress.get_score(user_id)
    |> case do
       nil -> json(conn, %{score: nil, result: false})
      score -> json(conn, %{score: score, result: true})
    end
  end

  @doc """
  Publish a url of a tournament.
  """
  def publish_url(conn, _params) do
    url = SecureRandom.urlsafe_base64()

    :milk
    |> Application.get_env(:environment)
    |> case do
      :dev -> "http://localhost:4001"
      :test -> "http://localhost:4001"
      _ -> "https://webserver-dot-e-players6814.an.r.appspot.com"
    end
    ~> origin

    json(conn, %{url: "#{origin}/api/tournament/url/#{url}", result: true})
  end

  @doc """
  Get members of a match.
  TODO: ログの処理書き足し
  HACK: リファクタリング
  """
  def get_match_members(conn, %{"tournament_id" => tournament_id}) do
    tournament_id
    |> Tournaments.get_tournament_including_logs()
    |> case do
      {:ok, %Tournament{}    = tournament} -> load_match_members(tournament)
      {:ok, %TournamentLog{} = tournament} -> load_match_members_from_log(tournament)
      _                                    -> {:error, "tournament is nil"}
    end
    |> case do
      {:ok, master, assistants, entrants, teams} ->
        render(conn, "tournament_members.json", master: master, assistants: assistants, entrants: entrants, teams: teams)
      {:error, error} ->
        render(conn, "error.json", error: error)
    end
  end

  @spec load_match_members(Tournament.t()) :: {:ok, User.t(), [User.t()], [User.t()], [Team.t()]}
  defp load_match_members(%Tournament{master_id: master_id, id: tournament_id}) do
    master = Accounts.get_user(master_id)

    tournament_id
    |> Tournaments.get_assistants()
    |> Enum.map(&Accounts.get_user(&1.user_id))
    ~> assistants

    tournament_id
    |> Tournaments.get_entrants()
    |> Enum.map(&Accounts.get_user(&1.user_id))
    ~> entrants

    tournament_id
    |> Tournaments.get_confirmed_teams()
    |> Enum.map(fn team ->
      team.id
      |> Tournaments.get_leader()
      |> Map.get(:user)
      ~> user

      team
      |> Map.put(:name, user.name)
      |> Map.put(:icon_path, user.icon_path)
    end)
    ~> teams

    {:ok, master, assistants, entrants, teams}
  end

  @spec load_match_members_from_log(TournamentLog.t()) :: {:ok, User.t(), [User.t()], [User.t()], [TeamLog.t()]}
  defp load_match_members_from_log(%TournamentLog{master_id: master_id, tournament_id: tournament_id}) do
    master = Accounts.get_user(master_id)

    tournament_id
    |> Log.get_assistant_logs_by_tournament_id()
    |> Enum.map(&Accounts.get_user(&1.user_id))
    ~> assistants

    tournament_id
    |> Log.get_entrant_logs_by_tournament_id()
    |> Enum.map(&Accounts.get_user(&1.user_id))
    ~> entrants

    tournament_id
    |> Log.get_team_logs_by_tournament_id()
    |> Enum.map(fn team_log ->
      team_log
      |> Map.get(:team_id)
      |> Tournaments.get_leader()
      |> Map.get(:user)
      ~> user

      team_log
      |> Map.put(:name, user.name)
      |> Map.put(:icon_path, user.icon_path)
    end)
    ~> teams

    {:ok, master, assistants, entrants, teams}
  end

  @doc """
  Get duplicate members.
  """
  def get_duplicate_claim_members(conn, %{"tournament_id" => tournament_id}) do
    users =
      tournament_id
      |> Progress.get_duplicate_users()
      |> Enum.map(fn user_id ->
        Accounts.get_user(user_id)
      end)

    render(conn, "users.json", users: users)
  end

  @doc """
  Get game masters.
  """
  def get_game_masters(conn, %{"tournament_id" => tournament_id}) do
    masters = Tournaments.get_masters(tournament_id)

    render(conn, "masters.json", masters: masters)
  end

  @doc """
  Get tournament entrants.
  """
  def get_entrants(conn, %{"tournament_id" => tournament_id}) do
    tournament_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.get_entrants()
    ~> entrants

    render(conn, "entrants.json", entrants: entrants)
  end

  @doc """
  iosの起動時に画面遷移をするために必要な情報を取り出すための関数
  get match informationと比べてtournament idを取得しないといけないのでコストが少し高い
  """
  def data_for_ios(conn, %{"user_id" => user_id}) do
    user_id = Tools.to_integer_as_needed(user_id)

    user_id
    |> started_tournament()
    |> case do
      nil         -> render(conn, "error.json", error: "tournament is nil")
      tournament  -> render(conn, "match_info.json", match_info: do_get_match_information(tournament.id, user_id))
    end
  end

  defp started_tournament(user_id) do
    user_id
    |> do_relevant()
    |> Enum.filter(&(&1.is_started))
    |> List.first()
  end

  @doc """
  Get information for match
  - Opponent
  - Current rank
  - State
  - Score(optional)
  - Whether it is team
  - Whether it is team leader
  """
  def get_match_information(conn, %{"tournament_id" => tournament_id, "user_id" => user_id}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    user_id = Tools.to_integer_as_needed(user_id)

    match_info = do_get_match_information(tournament_id, user_id)

    render(conn, "match_info.json", match_info: match_info)
  end

  @spec do_get_match_information(integer(), integer()) :: MatchInformation.t()
  defp do_get_match_information(tournament_id, user_id) do
    tournament = get_tournament_for_match_info(tournament_id)

    rank = get_rank(tournament, user_id)
    state = Tournaments.state!(tournament.id, user_id)
    score = load_score(state, tournament, user_id)

    opponent = get_opponent_for_match_info(tournament_id, user_id, state)
    is_leader = Tournaments.is_leader?(tournament_id, user_id)

    id = Progress.get_necessary_id(tournament_id, user_id)
    is_coin_head = is_coin_head_on_match_info?(opponent, tournament, id)
    custom_detail = Tournaments.get_custom_detail_by_tournament_id(tournament_id)
    is_attacker_side = Progress.is_attacker_side?(id, tournament_id)

    tournament_id
    |> Tournaments.get_selected_map(id)
    |> case do
      {:ok, map} -> map
      {:error, _} -> nil
    end
    ~> map

    is_team = tournament.is_team
    rule = tournament.rule

    %MatchInformation{
      tournament:       tournament,
      opponent:         opponent,
      rank:             rank,
      is_team:          is_team,
      is_leader:        is_leader,
      is_attacker_side: is_attacker_side,
      score:            score,
      state:            state,
      map:              map,
      rule:             rule,
      is_coin_head:     is_coin_head,
      custom_detail:    custom_detail
    }
  end

  defp get_opponent_for_match_info(_, _, "IsAlone"), do: nil
  defp get_opponent_for_match_info(tournament_id, user_id, _) do
    tournament_id
    |> Tournaments.get_opponent(user_id)
    |> case do
      {:ok, opponent} when not is_nil(opponent) -> opponent
      _                                         -> nil
    end
  end

  @spec get_tournament_for_match_info(integer()) :: Tournament.t() | TournamentLog.t() | nil
  defp get_tournament_for_match_info(tournament_id) do
    tournament_id
    |> Tournaments.get_tournament_including_logs()
    |> case do
      {:ok, %Tournament{} = tournament}        -> tournament
      {:ok, %TournamentLog{} = tournament_log} -> Map.put(tournament_log, :id, tournament_log.tournament_id)
      _                                        -> nil
    end
  end

  @spec is_coin_head_on_match_info?(User.t() | Team.t() | nil, Tournament.t() | TournamentLog.t() | nil,  integer()) :: boolean() | nil
  defp is_coin_head_on_match_info?(nil, _, _), do: nil
  defp is_coin_head_on_match_info?(_, %Tournament{enabled_coin_toss: false}, _), do: nil
  defp is_coin_head_on_match_info?(%User{id: opponent_id}, %Tournament{is_team: false, id: id}, user_id) do
    Tournaments.is_head_of_coin?(id, user_id, opponent_id)
  end
  defp is_coin_head_on_match_info?(%Team{id: opponent_id}, %Tournament{is_team: true, id: id}, team_id) do
    Tournaments.is_head_of_coin?(id, team_id, opponent_id)
  end

  @spec get_rank(Tournament.t() | nil, integer()) :: integer() | nil
  defp get_rank(nil, _), do: nil
  defp get_rank(tournament, user_id) do
    if tournament.is_team do
      tournament.id
      |> Tournaments.get_team_by_tournament_id_and_user_id(user_id)
      |> get_team_rank(tournament.id, user_id)
    else
      tournament.id
      |> Tournaments.get_rank(user_id)
      |> case do
        {:ok, rank} -> rank
        {:error, _} -> nil
      end
    end
  end

  defp get_team_rank(nil, tournament_id, user_id) do
    tournament_id
    |> Log.get_team_log_by_tournament_id_and_user_id(user_id)
    |> get_team_log_rank()
  end

  defp get_team_rank(team, _, _), do: team.rank

  @spec get_team_log_rank(TournamentLog.t() | nil) :: integer() | nil
  defp get_team_log_rank(nil), do: nil
  defp get_team_log_rank(team_log), do: team_log.rank

  @spec load_score(String.t(), Tournament.t() | TournamentLog.t(), integer()) :: integer()
  defp load_score("IsPending", tournament, user_id) do
    if tournament.is_team do
      team = Tournaments.get_team_by_tournament_id_and_user_id(tournament.id, user_id)
      Progress.get_score(tournament.id, team.id)
    else
      Progress.get_score(tournament.id, user_id)
    end
  end

  defp load_score(_, _, _), do: nil

  @doc """
  Finish tournament.
  """
  def finish(conn, %{"tournament_id" => tournament_id, "user_id" => user_id}) do
    tournament_id
    |>  Tournaments.finish(user_id)
    |> case do
      {:ok, _} -> true
      _ -> false
    end
    ~> result

    tournament_id
    |> Progress.get_match_list_with_fight_result()
    |> inspect(charlists: false)
    |> (fn str ->
          %{"tournament_id" => tournament_id, "match_list_with_fight_result_str" => str}
        end).()
    |> Progress.create_match_list_with_fight_result_log()

    Progress.delete_match_list(tournament_id)
    Progress.delete_match_list_with_fight_result(tournament_id)
    Progress.delete_match_pending_list_of_tournament(tournament_id)
    Progress.delete_fight_result_of_tournament(tournament_id)
    Progress.delete_duplicate_users_all(tournament_id)

    json(conn, %{result: result})
  end

  @doc """
  Get data with fight result for presenting tournament brackets.
  """
  def brackets_with_fight_result(conn, %{"tournament_id" => tournament_id}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    match_list = Progress.get_match_list_with_fight_result(tournament_id)

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
    tournament_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.data_with_scores_for_flexible_brackets()
    ~> brackets
    |> Enum.count()
    |> Kernel.*(2)
    |> Tournamex.Number.closest_number_to_power_of_two()
    ~> count

    json(conn, %{result: true, data: brackets, count: count})
  end

  @doc """
  Registers PID of start notification.
  The notification is handled in Web Server, so the pid does not belong to this server.
  """
  def register_pid_of_start_notification(conn, %{"tournament_id" => tournament_id, "pid" => pid}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    # FIXME: エラーハンドリング
    tournament_id
    |> Tournaments.load_tournament()
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

  defp add_queue_tournament_start_push_notice(%Tournament{event_date: event_date}) when is_nil(event_date), do: {:error, "event date is nil"}
  defp add_queue_tournament_start_push_notice(%Tournament{event_date: event_date, id: id}) do
    %{reminder_to_start_tournament: id}
    |> Oban.Processer.new(scheduled_at: event_date)
    |> Oban.insert()
    |> elem(1)
    ~> job

    case job.errors == [] do
      true -> {:ok, job.id}
      false -> {:error, job.errors}
    end
  end

  defp update_queue_tournament_start_push_notice(tournament) do
    case Tournaments.get_push_notice_job("reminder_to_start_tournament", tournament.id) do
      nil ->
        IO.puts("notice job not found")

      job ->
        Oban.cancel_job(job.id)
        add_queue_tournament_start_push_notice(tournament)
    end
  end

  def redirect_by_url(conn, params) do
    params
    |> Map.get("url")
    ~> token
    |> Tournaments.get_tournament_by_url_token()
    ~> tournament

    domain = Application.get_env(:milk, :domain)

    params
    |> Map.get("os_name")
    |> case do
      "iOS" ->
        "e-players://e-players/tournament/#{token}"

      _ ->
        "#{domain}/tournament/information?tournament_id=#{tournament.id}"
    end
    ~> redirect_url

    json(conn, %{result: true, url: redirect_url})
  end
end

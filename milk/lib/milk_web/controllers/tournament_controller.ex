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

  alias Milk.Tournaments.{
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
      tournament
      |> Map.get(:id)
      |> Tournaments.get_entrants()
      |> Enum.map(fn entrant ->
        Accounts.get_user(entrant.user_id)
      end)
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
      |> Enum.map(fn entrant ->
        Accounts.get_user(entrant.user_id)
      end)
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
  def create(conn, %{"tournament" => tournament_params, "image" => image, "options" => options}) do
    # coveralls-ignore-start
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
    ~> thumbnail_path

    if is_binary(tournament_params) do
      Poison.decode!(tournament_params)
    else
      tournament_params
    end
    ~> tournament_params

    if is_nil(tournament_params["join"]) do
      render(conn, "error.json", error: "join parameter is nil")
    else
      tournament_params
      |> Map.put("enabled_coin_toss", tournament_params["enabled_coin_toss"] == "true")
      |> Map.put("multiple_selections", options)
      |> Tournaments.create_tournament(thumbnail_path)
      |> case do
        {:ok, %Tournament{} = tournament} ->
          if tournament_params["join"] == "true" do
            %{"user_id" => tournament.master_id, "tournament_id" => tournament.id}
            |> Tournaments.create_entrant()
          end

          tournament
          |> Map.put(:followers, Relations.get_followers(tournament.master_id))
          ~> tournament

          %{"user_id" => tournament.master_id, "game_name" => tournament.game_name, "score" => 7}
          |> Accounts.gain_score()

          add_queue_tournament_start_push_notice(tournament)

          if tournament do
            render(conn, "create.json", tournament: tournament)
          else
            render(conn, "error.json", error: nil)
          end

        {:error, error} ->
          render(conn, "error.json", error: error)

        _ ->
          render(conn, "error.json", error: nil)
      end
    end
  end

  def create(conn, %{"tournament" => tournament_params, "file" => file, "options" => options}) do
    create(conn, %{"tournament" => tournament_params, "image" => file, "options" => options})
  end

  def create(conn, %{"tournament" => tournament_params, "file" => file}) do
    create(conn, %{"tournament" => tournament_params, "file" => file, "options" => []})
  end

  @doc """
  Show tournament information.
  """
  def show(conn, params) do
    user_id = params["user_id"]
    id = Tools.to_integer_as_needed(params["tournament_id"])

    tournament = Tournaments.get_tournament(id)
    tournament_log = Log.get_tournament_log_by_tournament_id(id)

    cond do
      !is_nil(tournament) ->
        unless is_nil(user_id) do
          %{"user_id" => user_id, "game_name" => tournament.game_name, "score" => 1}
          |> Accounts.gain_score()
        end

        team = Enum.filter(tournament.team, fn team -> team.is_confirmed end)
        selections = Tournaments.get_multiple_selections_by_tournament_id(tournament.id)

        tournament
        |> Map.put(:team, team)
        |> Map.put(:multiple_selection, selections)
        ~> tournament

        render(conn, "tournament_info.json", tournament: tournament)

      !is_nil(tournament_log) ->
        entrants = Log.get_entrant_logs_by_tournament_id(tournament_log.tournament_id)
        tournament_log = Map.put(tournament_log, :entrants, entrants)

        unless is_nil(user_id) do
          %{"user_id" => user_id, "game_name" => tournament_log.game_name, "score" => 1}
          |> Accounts.gain_score()
        end

        render(conn, "tournament_log.json", tournament_log: tournament_log)

      true ->
        render(conn, "error.json", error: nil)
    end
  end

  @doc """
  Gets tournament info list for home screen.
  """
  def home(conn, %{"user_id" => user_id, "date_offset" => date_offset, "offset" => offset}) do
    user_id = Tools.to_integer_as_needed(user_id)
    offset = Tools.to_integer_as_needed(offset)

    date_offset
    |> Tournaments.home_tournament(offset, user_id)
    |> Enum.map(fn tournament ->
      tournament
      |> Map.get(:id)
      |> Tournaments.get_entrants()
      |> Enum.map(fn entrant ->
        Accounts.get_user(entrant.user_id)
      end)
      ~> entrants

      Map.put(tournament, :entrants, entrants)
    end)
    |> Enum.map(fn tournament ->
      tournament
      |> Map.get(:id)
      |> Tournaments.get_confirmed_teams()
      ~> teams

      Map.put(tournament, :teams, teams)
    end)
    ~> tournaments

    render(conn, "home.json", tournaments_info: tournaments)
  end

  def home(conn, %{"date_offset" => date_offset, "offset" => offset}) do
    date_offset
    |> Tournaments.home_tournament(offset)
    |> Enum.map(fn tournament ->
      tournament
      |> Map.get(:id)
      |> Tournaments.get_entrants()
      |> Enum.map(fn entrant ->
        Accounts.get_user(entrant.user_id)
      end)
      ~> entrants

      Map.put(tournament, :entrants, entrants)
    end)
    ~> tournaments

    render(conn, "home.json", tournaments_info: tournaments)
  end

  def home(conn, %{"filter" => "fav", "user_id" => user_id}) do
    user_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.home_tournament_fav()
    |> Enum.map(fn tournament ->
      tournament
      |> Map.get(:id)
      |> Tournaments.get_entrants()
      |> Enum.map(fn entrant ->
        Accounts.get_user(entrant.user_id)
      end)
      ~> entrants

      Map.put(tournament, :entrants, entrants)
    end)
    ~> tournaments

    render(conn, "home.json", tournaments_info: tournaments)
  end

  def home(conn, %{"filter" => "plan", "user_id" => user_id}) do
    user_id
    |> Tournaments.home_tournament_plan()
    |> Enum.map(fn tournament ->
      entrants =
        Tournaments.get_entrants(tournament.id)
        |> Enum.map(fn entrant ->
          Accounts.get_user(entrant.user_id)
        end)

      Map.put(tournament, :entrants, entrants)
    end)
    ~> tournaments

    render(conn, "home.json", tournaments_info: tournaments)
  end

  def home(conn, %{"filter" => "entry", "user_id" => user_id}) do
    user_id
    |> Tournaments.get_participating_tournaments()
    |> Enum.map(fn tournament ->
      entrants =
        Tournaments.get_entrants(tournament.id)
        |> Enum.map(fn entrant ->
          Accounts.get_user(entrant.user_id)
        end)

      Map.put(tournament, :entrants, entrants)
    end)
    ~> tournaments
    |> is_nil()
    |> unless do
      render(conn, "home.json", tournaments_info: tournaments)
    else
      render(conn, "error.json", error: nil)
    end
  end

  @doc """
  Get searched tournaments as home.
  """
  def search(conn, %{"user_id" => user_id, "text" => text}) do
    user_id
    |> Tournaments.search(text)
    |> Enum.map(fn tournament ->
      tournament
      |> Map.get(:id)
      |> Tournaments.get_entrants()
      |> Enum.map(fn entrant ->
        Accounts.get_user(entrant.user_id)
      end)
      ~> entrants

      Map.put(tournament, :entrants, entrants)
    end)
    ~> tournaments

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

      tournament
      |> Tournaments.update_tournament(tournament_params)
      |> case do
        {:ok, %Tournament{} = tournament} ->
          update_queue_tournament_start_push_notice(tournament)
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
    offset = Tools.to_integer_as_needed(offset)

    user_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.get_participating_tournaments(offset)
    |> Enum.map(fn tournament ->
      Tournaments.get_entrants(tournament.id)
      |> Enum.map(fn entrant ->
        Accounts.get_user(entrant.user_id)
      end)
      ~> entrants

      Map.put(tournament, :entrants, entrants)
    end)
    ~> tournaments
    |> is_nil()
    |> unless do
      render(conn, "home.json", tournaments_info: tournaments)
    else
      render(conn, "error.json", error: nil)
    end
  end

  def participating_tournaments(conn, %{"user_id" => user_id}) do
    tournaments =
      Tournaments.get_participating_tournaments(user_id)
      |> Enum.map(fn tournament ->
        Tournaments.get_entrants(tournament.id)
        |> Enum.map(fn entrant ->
          Accounts.get_user(entrant.user_id)
        end)
        ~> entrants

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
    user_id
    |> Tools.to_integer_as_needed()
    |> relevant()
    ~> tournaments

    render(conn, "index.json", tournament: tournaments)
  end

  defp relevant(user_id) do
    participatings = Tournaments.get_participating_tournaments(user_id)
    hostings = Tournaments.get_tournaments_by_master_id(user_id)

    user_id
    |> Tournaments.get_assistants_by_user_id()
    |> Enum.map(fn assistant ->
      Tournaments.get_tournament(assistant.tournament_id)
    end)
    ~> assistants

    Enum.uniq(participatings ++ hostings ++ assistants)
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

    tournament = Tournaments.get_tournament(tournament_id)
    entrants = Tournaments.get_entrants(tournament.id)

    # キャパシティの確認(個人)
    result = tournament.capacity > length(entrants)

    # キャパシティの確認(チーム)
    tournament.capacity
    |> Kernel.>(length(tournament.team))
    |> Kernel.and(result)
    ~> result

    # 自分が参加しているかどうか
    entrants
    |> Enum.all?(fn entrant ->
      entrant.user_id != user_id
    end)
    |> Kernel.and(result)
    ~> result

    # 時刻の確認（自分の主催している大会には参加できる）
    user_id
    |> relevant()
    |> Enum.all?(fn t ->
      tournament.master_id == user_id || t.event_date != tournament.event_date
    end)
    |> Kernel.and(result)
    ~> result

    # 自分がチームとして参加しているかどうか
    user_id
    |> Tournaments.has_requested_as_team?(tournament_id)
    |> Kernel.not()
    |> Kernel.and(result)
    ~> result

    requested? = Tournaments.has_requested_as_team?(user_id, tournament_id)
    confirmed? = Tournaments.has_confirmed_as_team?(user_id, tournament_id)

    json(conn, %{
      result: result,
      has_requested_as_team: requested?,
      has_confirmed_as_team: confirmed?
    })
  end

  @doc """
  Checks if the user is related to a started tournament.
  """
  def is_started_at_least_one(conn, %{"user_id" => user_id}) do
    user_id
    |> Tools.to_integer_as_needed()
    |> relevant()
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
    |> Map.get(:is_started)
    |> unless do
      tournament
      |> Map.get(:is_team)
      |> if do
        start_team_tournament(master_id, tournament)
      else
        start_tournament(master_id, tournament)
      end
      |> case do
        {:ok, match_list, match_list_with_fight_result} ->
          Oban.Processer.notify_tournament_start(tournament_id)

          render(conn, "match.json", %{
            match_list: match_list,
            match_list_with_fight_result: match_list_with_fight_result
          })

        {:error, nil, nil} ->
          render(conn, "error.json", error: nil)

        {:error, error, nil} ->
          render(conn, "error.json", error: Tools.create_error_message(error))
      end
    else
      render(conn, "error.json", error: "Tournament has already been started.")
    end
  end

  defp start_team_tournament(master_id, tournament) do
    case tournament.type do
      2 -> TournamentProgress.start_team_best_of_format(master_id, tournament)
      _ -> {:error, "unsupported tournament type", nil}
    end
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

  @doc """
  Get a thumbnail image of a tournament by tournament id.
  """
  def get_thumbnail_by_tournament_id(conn, %{"tournament_id" => id}) do
    case Tournaments.get_tournament(id) do
      nil ->
        json(conn, %{result: false})
      tournament -> path = tournament.thumbnail_path
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
        json(conn, %{result: true, b64: map.b64})
    end
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
  Get options by tournament id.
  """
  def options(conn, %{"tournament_id" => tournament_id}) do
    tournament_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.get_multiple_selections_by_tournament_id()
    |> IO.inspect()
    ~> options

    render(conn, "options.json", options: options)
  end

  @doc """
  Get icon of an option.
  """
  def get_option_icon(conn, %{"path" => path}) do
    :milk
    |> Application.get_env(:environment)
    |> case do
      :dev -> load_img(path)
      :test -> load_img(path)
      _ -> load_img_prod(path)
    end
    |> case do
      {:ok, b64} ->
        json(conn, %{b64: b64})
      {:error, error} ->
        render(conn, "error.json", error: error)
    end
  end

  defp load_img(path) do
    path
    |> File.read()
    |> case do
      {:ok, file} ->
        {:ok, Base.encode64(file)}
      {:error, error} ->
        {:error, error}
    end
  end

  defp load_img_prod(name) do
    name
    |> Objects.get()
    |> Map.get(:mediaLink)
    |> Image.get()
    |> case do
      {:ok, file} ->
        {:ok, Base.encode64(file)}
      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Ban maps.
  """
  def ban_maps(conn, %{"user_id" => user_id, "tournament_id" => tournament_id, "map_id_list" => map_id_list}) do
    user_id = Tools.to_integer_as_needed(user_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    map_id_list = Enum.map(map_id_list, fn id -> Tools.to_integer_as_needed(id) end)

    user_id
    |> Tournaments.ban_maps(tournament_id, map_id_list)
    |> case do
      {:ok, nil} ->
        json(conn, %{result: true})
      {:error, error} ->
        render(conn, "error.json", error: error)
    end
  end

  @doc """
  Choose a map.
  """
  def choose_map(conn, %{"user_id" => user_id, "tournament_id" => tournament_id, "map_id" => map_id}) do
    user_id = Tools.to_integer_as_needed(user_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    map_id = Tools.to_integer_as_needed(map_id)

    user_id
    |> Tournaments.choose_maps(tournament_id, [map_id])
    |> case do
      {:ok, nil} ->
        json(conn, %{result: true})
      {:error, error} ->
        render(conn, "error.json", error: error)
    end
  end

  @doc """
  Start a single match in the tournament.
  """
  def start_match(conn, %{"user_id" => user_id, "tournament_id" => tournament_id}) do
    user_id = Tools.to_integer_as_needed(user_id)

    # 大会がチーム用かどうかで分岐の処理を書く
    tournament_id
    |> Tools.to_integer_as_needed()
    ~> tournament_id
    |> Tournaments.get_tournament()
    |> Map.get(:is_team)
    |> if do
      start_team_match(tournament_id, user_id)
    else
      start_individual_match(tournament_id, user_id)
    end
    ~> result

    json(conn, %{result: result})
  end

  defp start_individual_match(tournament_id, user_id) do
    user_id
    |> TournamentProgress.get_match_pending_list(tournament_id)
    |> Kernel.==([])
    |> if do
      TournamentProgress.insert_match_pending_list_table(user_id, tournament_id)
    else
      false
    end
  end

  defp start_team_match(tournament_id, user_id) do
    tournament_id
    |> Tournaments.get_team_by_tournament_id_and_user_id(user_id)
    |> Map.get(:id)
    ~> team_id
    |> TournamentProgress.get_match_pending_list(tournament_id)
    |> Kernel.==([])
    |> if do
      TournamentProgress.insert_match_pending_list_table(team_id, tournament_id)
    else
      # FIXME: trueを返すことによってios側でどのユーザーでもコイントスの結果を見られるようにしているが、
      # もっと良い処理があるかもしれない
      true
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
        render(conn, "opponent.json", opponent: opponent)
      else
        {:wait, _} ->
          json(conn, %{result: false, opponent: nil, wait: true})

        _ ->
          render(conn, "error.json", error: nil)
      end
    else
      json(conn, %{result: false})
    end
  end

  def get_opponent(conn, %{"tournament_id" => tournament_id, "team_id" => team_id}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    team_id = Tools.to_integer_as_needed(team_id)

    tournament_id
    |> TournamentProgress.get_match_list()
    ~> match_list
    |> is_integer()
    |> unless do
      match_list
      |> Tournaments.find_match(team_id)
      |> Tournaments.get_opponent_team(team_id)
      |> case do
        {:ok, opponent} ->
          opponent
          |> Map.get("id")
          |> Tournaments.get_leader()
          |> Map.get(:user)
          |> Map.from_struct()
          |> Tools.atom_map_to_string_map()
          ~> leader

          render(conn, "opponent.json", opponent: opponent, leader: leader)

        {:wait, nil} ->
          json(conn, %{result: false, opponent: nil, wait: true})

        _ ->
          render(conn, "error.json", error: nil)
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
    |> Tournaments.get_tournament()
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
    |> Tournaments.get_tournament()
    ~> tournament
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

    pending_list = TournamentProgress.get_match_pending_list(user_id, tournament_id)

    unless pending_list == [] do
      [{{_, id}, _}] = pending_list
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

    score =
      if state == "IsPending" do
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

    # チーム大会かどうかを判別し、idを切り替える
    tournament_id
    |> Tournaments.get_tournament()
    |> Map.get(:is_team)
    |> if do
      tournament_id
      |> Tournaments.get_team_by_tournament_id_and_user_id(user_id)
      |> Map.get(:id)
      ~> team_id

      tournament_id
      |> TournamentProgress.get_match_list()
      |> Tournaments.find_match(team_id)
      |> Tournaments.get_opponent_team(team_id)
      |> case do
        {:ok, opponent} -> {:ok, opponent["id"], team_id}
        {:wait, nil} -> raise "The given user should wait for the opponent."
        _ -> raise "Unknown error on claim score."
      end
    else
      {:ok, opponent_id, user_id}
    end
    ~> {:ok, opponent_id, user_id}

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
            is_finished = finish_as_needed?(tournament_id, opponent_id)
            json(conn, %{validated: true, completed: true, is_finished: is_finished})

          n < score ->
            Tournaments.delete_loser_process(tournament_id, [opponent_id])
            Tournaments.score(tournament_id, user_id, opponent_id, score, n, match_index)
            TournamentProgress.delete_match_pending_list(user_id, tournament_id)
            TournamentProgress.delete_match_pending_list(opponent_id, tournament_id)
            TournamentProgress.delete_score(tournament_id, user_id)
            TournamentProgress.delete_score(tournament_id, opponent_id)
            is_finished = finish_as_needed?(tournament_id, user_id)
            json(conn, %{validated: true, completed: true, is_finished: is_finished})

          true ->
            # notify_on_duplicate_match(tournament_id, user_id, opponent_id)
            json(conn, %{validated: false, completed: false, is_finished: false})
        end

      [] ->
        json(conn, %{validated: true, completed: false, is_finished: false})
    end
  end

  @doc """
  Flip Coin.
  """
  def flip_coin(conn, %{"tournament_id" => tournament_id, "user_id" => user_id}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    user_id = Tools.to_integer_as_needed(user_id)

    result = Tournaments.flip_coin(user_id, tournament_id)

    json(conn, %{result: result})
  end

  # チーム対応
  defp notify_on_duplicate_match(tournament_id, user_id, opponent_id) do
    user = Accounts.get_user(user_id)
    opponent = Tournaments.get_opponent(opponent_id)

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
  end

  defp finish_as_needed?(tournament_id, winner_id) do
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
      true
    else
      false
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
        finish_as_needed?(tournament_id, winner["id"])

      {:wait, nil} ->
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
    url
    |> String.split("/")
    |> Enum.reverse()
    |> hd()
    ~> token

    token
    |> Tournaments.get_tournament_by_url_token()
    ~> tournament

    team = Enum.filter(tournament.team, fn team -> team.is_confirmed end)
    selections = Tournaments.get_multiple_selections_by_tournament_id(tournament.id)

    tournament
    |> Map.put(:team, team)
    |> Map.put(:multiple_selection, selections)
    ~> tournament

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

    # conn
    # |> Map.get(:scheme)
    # |> to_string()
    # ~> scheme

    # conn
    # |> Map.get(:req_headers)
    # |> List.pop_at(2)
    # |> elem(0)
    # |> elem(1)
    # ~> host

    # origin = "#{scheme}://#{host}"

    :milk
    |> Application.get_env(:environment)
    |> case do
      :dev -> "http://localhost:4001"
      :test -> "http://localhost:4001"
      _ -> "https://webserver-dot-e-players6814.an.r.appspot.com"
    end
    ~> origin

    # json(conn, %{url: "e-players://e-players/tournament/" <> url, result: true})
    json(conn, %{url: "#{origin}/api/tournament/url/#{url}", result: true})
  end

  @doc """
  Get members of a match.
  TODO: ログの処理書き足し
  """
  def get_match_members(conn, %{"tournament_id" => tournament_id}) do
    tournament = Tournaments.get_tournament(tournament_id)

    if tournament do
      master = Accounts.get_user(tournament.master_id)

      Tournaments.get_assistants(tournament.id)
      |> Enum.map(fn assistant ->
        Accounts.get_user(assistant.user_id)
      end)
      ~> assistants

      Tournaments.get_entrants(tournament.id)
      |> Enum.map(fn entrant ->
        Accounts.get_user(entrant.user_id)
      end)
      ~> entrants

      tournament.id
      |> Tournaments.get_confirmed_teams()
      |> Enum.map(fn team ->
        team
        |> Map.get(:id)
        |> Tournaments.get_leader()
        |> Map.get(:user)
        ~> user

        team
        |> Map.put(:name, user.name)
        |> Map.put(:icon_path, user.icon_path)
      end)
      ~> teams

      render(conn, "tournament_members.json",
        master: master,
        assistants: assistants,
        entrants: entrants,
        teams: teams
      )
    else
      tournament_id
      |> Tournaments.get_tournament_including_logs()
      |> elem(1)
      ~> tournament_log
      |> is_nil()
      |> unless do
        master = Accounts.get_user(tournament_log.master_id)

        tournament_id
        |> Log.get_entrant_logs_by_tournament_id()
        |> Enum.map(fn entrant_log ->
          Accounts.get_user(entrant_log.user_id)
        end)
        ~> entrants

        tournament_id
        |> Log.get_assistant_logs_by_tournament_id()
        |> Enum.map(fn assistant_log ->
          Accounts.get_user(assistant_log.user_id)
        end)
        ~> assistants

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

        render(conn, "tournament_members.json",
          master: master,
          assistants: assistants,
          entrants: entrants,
          teams: teams
        )
      else
        render(conn, "error.json", error: nil)
      end
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

    tournament_id
    |> Tournaments.get_tournament_including_logs()
    |> elem(1)
    ~> tournament
    |> Map.get(:is_team)
    ~> is_team
    |> if do
      tournament_id
      |> Tournaments.get_team_by_tournament_id_and_user_id(user_id)
      ~> team
      |> is_nil()
      |> if do
        tournament_id
        |> Log.get_team_log_by_tournament_id_and_user_id(user_id)
        ~> team_log
        |> Map.get(:team_member)
        |> Enum.filter(fn member_log ->
          member_log.is_leader
        end)
        |> Enum.all?(fn member_log ->
          member_log.user_id == user_id
        end)
        ~> is_leader

        {nil, team_log.rank, is_leader}
      else
        team.id
        |> Tournaments.get_leader()
        |> Map.get(:user)
        ~> leader
        |> Map.get(:id)
        |> Kernel.==(user_id)
        ~> is_leader

        team
        |> Map.get(:tournament_id)
        |> TournamentProgress.get_match_list()
        |> Tournaments.find_match(team.id)
        |> Tournaments.get_opponent_team(team.id)
        |> case do
          {:ok, opponent} ->
            opponent
            |> Map.get("id")
            |> Tournaments.get_leader()
            |> Map.get(:user)
            ~> opponent_leader

            opponent
            |> Map.put("name", opponent_leader.name)
            |> Map.put("icon_path", opponent_leader.icon_path)
            ~> opponent

            {opponent, team.rank, is_leader}

          {:wait, nil} ->
            {nil, team.rank, is_leader}

          _ ->
            {nil, team.rank, is_leader}
        end
      end
    else
      tournament_id
      |> TournamentProgress.get_match_list()
      |> Tournaments.find_match(user_id)
      |> Tournaments.get_opponent(user_id)
      |> case do
        {:ok, opponent} ->
          rank = Tournaments.get_rank(tournament_id, user_id)
          {opponent, rank, nil}

        {:wait, nil} ->
          rank = Tournaments.get_rank(tournament_id, user_id)
          {nil, rank, nil}

        _ ->
          rank = Tournaments.get_rank(tournament_id, user_id)
          {nil, rank, nil}
      end
    end
    ~> {opponent, rank, is_leader}

    tournament_id
    |> Tournaments.state!(user_id)
    ~> state
    |> Kernel.==("IsPending")
    |> if do
      if tournament.is_team do
        tournament_id
        |> Tournaments.get_team_by_tournament_id_and_user_id(user_id)
        ~> team

        tournament_id
        |> TournamentProgress.get_score(team.id)
      else
        tournament_id
        |> TournamentProgress.get_score(user_id)
      end
      |> case do
        [] -> nil
        score -> score
      end
    end
    ~> score

    # user_idとtournament_idを足したもののhashで比較を行い、大きい方がコインの表
    opponent
    |> is_nil()
    |> Kernel.||(!tournament.enabled_coin_toss)
    |> unless do
      if is_team do
        opponent["id"]
        |> Tournaments.get_leader()
        |> Map.get(:user)
        |> Map.get(:id)
        ~> opponent_id

        tournament_id
        |> Tournaments.get_team_by_tournament_id_and_user_id(user_id)
        |> Map.get(:id)
        |> Tournaments.get_leader()
        |> Map.get(:user)
        |> Map.get(:id)
        ~> my_id

        {my_id, opponent_id}
      else
        {user_id, opponent["id"]}
      end
      ~> {my_id, opponent_id}

      Tournaments.is_head_of_coin?(tournament_id, my_id, opponent_id)
    else
      nil
    end
    ~> is_coin_head

    tournament_id
    |> Tournaments.get_custom_detail_by_tournament_id()
    ~> custom_detail

    render(conn, "match_info.json", %{
      opponent: opponent,
      rank: rank,
      is_team: is_team,
      is_leader: is_leader,
      score: score,
      state: state,
      is_coin_head: is_coin_head,
      custom_detail: custom_detail
    })
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

  defp add_queue_tournament_start_push_notice(tournament) do
    job =
      %{reminder_to_start_tournament: tournament.id}
      |> Oban.Processer.new(scheduled_at: tournament.event_date)
      |> Oban.insert()
      |> elem(1)

    result = if Map.get(job, :errors) |> length == 0, do: true, else: false

    case result do
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

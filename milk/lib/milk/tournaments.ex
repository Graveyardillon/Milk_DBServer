defmodule Milk.Tournaments do
  @moduledoc """
  The Tournaments context.
  """
  use Timex

  import Ecto.Query, warn: false
  import Common.{
    Sperm,
    Tools
  }

  alias Common.{
    FileUtils,
    Tools
  }

  alias Ecto.Multi

  alias Milk.{
    Accounts,
    Chat,
    Discord,
    Log,
    Notif,
    Relations,
    Repo
  }

  alias Milk.Accounts.{
    Relation,
    User
  }

  alias Milk.Chat.ChatRoom
  alias Milk.Games.Game

  alias Milk.Log.{
    AssistantLog,
    EntrantLog,
    TeamLog,
    TournamentChatTopicLog,
    TournamentLog
  }

  alias Milk.Notif.Notification

  alias Milk.Tournaments.{
    Assistant,
    Entrant,
    MapSelection,
    Progress,
    Rules,
    Team,
    TeamInvitation,
    TeamMember,
    Tournament,
    TournamentChatTopic,
    TournamentCustomDetail
  }
  alias Milk.Tournaments.Rules.{
    Basic,
    FlipBan
  }

  require Integer
  require Logger

  @type match_list :: [any()]
  @type match_list_with_fight_result :: [any()]

  @doc """
  Gets a single tournament.

  Raises `Ecto.NoResultsError` if the Tournament does not exist.
  """
  @spec get_tournament(integer()) :: Tournament.t() | nil
  def get_tournament(id) do
    Tournament
    |> Repo.get(id)
    |> Repo.preload(:team)
    |> Repo.preload(:entrant)
    |> Repo.preload(:assistant)
    |> Repo.preload(:master)
    |> Repo.preload(:map)
    |> Repo.preload(:custom_detail)
    ~> tournament

    if tournament do
      tournament
      |> Map.get(:entrant)
      |> Enum.map(fn entrant ->
        entrant
        |> Repo.preload(:user)
        |> Map.get(:user)
        |> Repo.preload(:auth)
        ~> user

        Map.put(entrant, :user, user)
      end)
      ~> entrants

      Map.put(tournament, :entrant, entrants)
    end
  end

  @doc """
  Returns the list of tournament for home screen.
  """
  @spec home_tournament(any(), integer(), integer() | nil) :: [Tournament.t()]
  def home_tournament(date_offset, offset, user_id \\ nil) do
    offset = Tools.to_integer_as_needed(offset)

    user_id
    |> Relations.blocked_users()
    |> Enum.map(& &1.blocked_user_id)
    ~> blocked_user_id_list

    Timex.now()
    |> Timex.add(Timex.Duration.from_days(1))
    |> Timex.to_datetime()

    Tournament
    |> where([t], t.deadline > ^date_offset and t.create_time < ^date_offset)
    |> where([t], not (t.master_id in ^blocked_user_id_list))
    |> order_by([t], asc: :event_date)
    |> offset(^offset)
    |> limit(5)
    |> Repo.all()
    |> Repo.preload(:entrant)
    |> Repo.preload(:team)
    |> Repo.preload(:custom_detail)
  end

  @doc """
  Returns the list of tournament which is filtered by "fav" for home screen.
  """
  @spec home_tournament_fav(integer()) :: [Tournament.t()]
  def home_tournament_fav(user_id) do
    Relation
    |> where([r], r.follower_id == ^user_id)
    |> Repo.all()
    |> Enum.map(& &1.followee_id)
    ~> user_id_list

    Tournament
    |> where([t], t.master_id in ^user_id_list)
    |> date_filter()
    |> Repo.all()
    |> Repo.preload(:entrant)
    |> Repo.preload(:team)
    |> Repo.preload(:custom_detail)
  end

  @doc """
  Returns the list of tournament which is filtered by "plan" for home screen.
  """
  @spec home_tournament_plan(integer()) :: [Tournament.t()]
  def home_tournament_plan(user_id) do
    Tournament
    |> where([t], t.master_id == ^user_id)
    |> date_filter()
    |> Repo.all()
    |> Repo.preload(:entrant)
    |> Repo.preload(:team)
    |> Repo.preload(:custom_detail)
  end

  @doc """
  Get searched tournaments as home.
  """
  @spec search(integer(), String.t()) :: [Tournament.t()]
  def search(_user_id, text) do
    like = "%#{text}%"

    Tournament
    |> where([t], like(t.name, ^like) or like(t.game_name, ^like))
    |> date_filter()
    |> Repo.all()
    |> Repo.preload(:entrant)
    |> Repo.preload(:team)
    |> Repo.preload(:custom_detail)
  end

  @spec date_filter(Ecto.Query.t()) :: Ecto.Query.t()
  defp date_filter(query) do
    query
    |> where([e], e.deadline > ^Timex.now() or is_nil(e.deadline))
    |> order_by([e], asc: :event_date)
  end

  @doc """
  Returns the list of tournament specified with a game id.
  """
  @spec get_tournament_by_game_id(integer()) :: Tournament.t()
  def get_tournament_by_game_id(game_id) do
    Tournament
    |> where([t], t.game_id == ^game_id)
    |> Repo.one()
  end

  @doc """
  Get tournament by discord server id
  """
  @spec get_tournament_by_discord_server_id(String.t()) :: Tournament.t() | nil
  def get_tournament_by_discord_server_id(discord_server_id) do
    Tournament
    |> where([t], t.discord_server_id == ^discord_server_id)
    |> Repo.one()
  end

  @doc """
  Get a tournament by room id.
  """
  @spec get_tournament_by_room_id(integer()) :: Tournament.t() | nil
  def get_tournament_by_room_id(chat_room_id) do
    TournamentChatTopic
    |> where([tct], tct.chat_room_id == ^chat_room_id)
    |> Repo.one()
    |> get_tournament_by_topic()
  end

  @spec get_tournament_by_topic(TournamentChatTopic.t() | nil) :: Tournament.t() | nil
  defp get_tournament_by_topic(nil), do: nil

  defp get_tournament_by_topic(topic) do
    Tournament
    |> where([t], t.id == ^topic.tournament_id)
    |> Repo.one()
  end

  @doc """
  Returns tournaments which are filtered by master id.
  """
  @spec get_tournaments_by_master_id(integer()) :: [Tournament.t()]
  def get_tournaments_by_master_id(user_id) do
    Tournament
    |> where([t], t.master_id == ^user_id)
    |> Repo.all()
    |> Repo.preload(:entrant)
    |> Repo.preload(:custom_detail)
    |> Repo.preload(:map)
    |> Repo.preload(:team)
    |> Repo.preload(:master)
    |> Repo.preload(:assistant)
  end

  @doc """
  Get tournament logs by master id
  """
  @spec get_tournament_logs_by_master_id(integer) :: [TournamentLog.t()]
  def get_tournament_logs_by_master_id(user_id) do
    TournamentLog
    |> where([tl], tl.master_id == ^user_id)
    |> order_by([tl], asc: :event_date)
    |> Repo.all()
    |> Enum.reject(&is_nil(&1.tournament_id))
    |> Enum.map(fn tournament_log ->
      EntrantLog
      |> where([el], el.tournament_id == ^tournament_log.tournament_id)
      |> Repo.all()
      ~> entrants

      Map.put(tournament_log, :entrants, entrants)
    end)
  end

  @doc """
  Returns tournaments which are filtered by user id of assistant.
  """
  @spec get_tournaments_by_assistant_id(integer()) :: [Tournament.t()]
  def get_tournaments_by_assistant_id(user_id) do
    Assistant
    |> where([a], a.user_id == ^user_id)
    |> Repo.all()
    |> Enum.map(fn assistant ->
      __MODULE__.get_tournament(assistant.tournament_id)
    end)
  end

  @doc """
  Returns ongoing tournaments of certain user.
  """
  @spec get_ongoing_tournaments_by_master_id(integer()) :: [Tournament.t()]
  def get_ongoing_tournaments_by_master_id(user_id) do
    Tournament
    |> where([t], t.master_id == ^user_id)
    |> where([t], t.event_date > ^Timex.now() or (is_nil(t.event_date) and t.is_started))
    |> order_by([t], asc: :event_date)
    |> Repo.all()
    |> Repo.preload(:entrant)
    |> Repo.preload(:custom_detail)
    |> Repo.preload(:map)
    |> Repo.preload(:team)
    |> Repo.preload(:master)
    |> Repo.preload(:assistant)
  end

  @doc """
  Gets single tournament by url.
  """
  @spec get_tournament_by_url(String.t()) :: Tournament.t()
  def get_tournament_by_url(url) do
    Tournament
    |> where([t], t.url == ^url)
    |> Repo.one()
    |> Repo.preload(:custom_detail)
    |> Repo.preload(:team)
    |> Repo.preload(:entrant)
    |> Repo.preload(:assistant)
    |> Repo.preload(:master)
    ~> tournament

    unless is_nil(tournament) do
      tournament
      |> Map.get(:entrant)
      |> Enum.map(fn entrant ->
        entrant
        |> Repo.preload(:user)
        |> Map.get(:user)
        |> Repo.preload(:auth)
        ~> user

        Map.put(entrant, :user, user)
      end)
      ~> entrants

      Map.put(tournament, :entrant, entrants)
    end
  end

  @doc """
  Gets single tournament or tournament log.
  If tournament does not exist in the table, it checks log table.
  """
  @spec get_tournament_including_logs(integer()) ::
          {:ok, Tournament.t()} | {:ok, TournamentLog.t()} | {:error, nil}
  def get_tournament_including_logs(tournament_id) do
    tournament_id
    |> __MODULE__.get_tournament()
    |> do_get_tournament_including_logs(tournament_id)
  end

  defp do_get_tournament_including_logs(nil, tournament_id) do
    tournament_id
    |> Log.get_tournament_log_by_tournament_id()
    |> get_tournament_log()
  end

  defp do_get_tournament_including_logs(tournament, _), do: {:ok, tournament}

  defp get_tournament_log(nil), do: {:error, nil}
  defp get_tournament_log(log), do: {:ok, log}

  @doc """
  Get tournaments which the user participating in.
  It includes team.
  """
  @spec get_participating_tournaments(integer(), integer()) :: [Tournament.t()]
  def get_participating_tournaments(user_id, offset \\ 0) do
    Tournament
    |> join(:inner, [t], e in Entrant, on: t.id == e.tournament_id)
    |> where([t, e], e.user_id == ^user_id)
    |> offset(^offset)
    |> Repo.all()
    |> Repo.preload(:entrant)
    |> Repo.preload(:custom_detail)
    |> Repo.preload(:map)
    |> Repo.preload(:team)
    |> Repo.preload(:master)
    |> Repo.preload(:assistant)
    ~> entrants

    Tournament
    |> join(:inner, [t], te in Team, on: t.id == te.tournament_id)
    |> join(:inner, [t, te], tm in TeamMember, on: te.id == tm.team_id)
    |> where([t, te, tm], tm.user_id == ^user_id)
    |> where([t, te, tm], te.is_confirmed)
    |> offset(^offset)
    |> Repo.all()
    |> Repo.preload(:entrant)
    |> Repo.preload(:custom_detail)
    |> Repo.preload(:map)
    |> Repo.preload(:team)
    |> Repo.preload(:master)
    |> Repo.preload(:assistant)
    |> Enum.concat(entrants)
    |> Enum.uniq()
  end

  @doc """
  Get pending tournaments.
  Pending tournament means like "our team invitation for the tournament is still in progress "
  """
  @spec get_pending_tournaments(integer()) :: [Tournament.t()]
  def get_pending_tournaments(user_id) do
    Tournament
    |> join(:inner, [t], te in Team, on: t.id == te.tournament_id)
    |> join(:inner, [t, te], tm in TeamMember, on: te.id == tm.team_id)
    |> where([t, te, tm], tm.user_id == ^user_id)
    |> where([t, te, tm], not te.is_confirmed)
    |> Repo.all()
    |> Repo.preload(:entrant)
    |> Repo.preload(:custom_detail)
    |> Repo.preload(:map)
    |> Repo.preload(:team)
    |> Repo.preload(:master)
    |> Repo.preload(:assistant)
  end

  @doc """
  Get a list of master users' information of a tournament
  """
  @spec get_masters(integer()) :: [User.t()]
  def get_masters(tournament_id) do
    tournament = __MODULE__.get_tournament(tournament_id)

    User
    |> where([u], u.id == ^tournament.master_id)
    |> Repo.all()
  end

  @doc """
  Get tournament by url token
  """
  @spec get_tournament_by_url_token(String.t()) :: Tournament.t()
  def get_tournament_by_url_token(token) do
    Tournament
    |> where([t], t.url_token == ^token)
    |> Repo.one()
    |> Repo.preload(:team)
    |> Repo.preload(:entrant)
    |> Repo.preload(:assistant)
    |> Repo.preload(:master)
    |> Repo.preload(:custom_detail)
  end

  @doc """
  Create tournament.
  """
  @spec create_tournament(map(), String.t() | nil) :: {:ok, Tournament.t()} | {:error, Ecto.Changeset.t()}
  def create_tournament(attrs, thumbnail_path \\ "") do
    attrs = modify_necessary_fields(attrs)

    with {:ok, _} <- validate_fields(attrs),
         {:ok, tournament} <- do_create_tournament(attrs, thumbnail_path),
         {:ok, nil} <- join_chat_topics_on_create_tournament(tournament),
         {:ok, _} <- add_necessary_fields(tournament, attrs) do
      {:ok, tournament}
    else
      error -> error
    end
  end

  @spec modify_necessary_fields(map()) :: map()
  defp modify_necessary_fields(attrs) do
    master_id = Tools.to_integer_as_needed(attrs["master_id"])
    platform_id = Tools.to_integer_as_needed(attrs["platform"])
    game_id = if attrs["game_id"] != "" && !is_nil(attrs["game_id"]), do: attrs["game_id"]

    attrs
    |> Map.put("master_id", master_id)
    |> Map.put("platform", platform_id)
    |> Map.put("game_id", game_id)
    |> put_token_as_needed()
  end

  defp validate_fields(attrs) do
    case attrs["rule"] do
      "flipban" -> validate_flipban_fields(attrs)
      _ -> validate_basic_fields(attrs)
    end
  end

  defp validate_basic_fields(attrs) do
    {:ok, attrs}
  end

  defp validate_flipban_fields(attrs) do
    {:ok, attrs}
  end

  defp do_create_tournament(%{"master_id" => master_id, "platform" => platform, "game_id" => game_id} = attrs, thumbnail_path) do
    tournament = %Tournament{
      master_id: master_id,
      game_id: game_id,
      thumbnail_path: thumbnail_path,
      platform_id: platform
    }
    tournament_schema = Tournament.create_changeset(tournament, attrs)

    Multi.new()
    |> Multi.insert(:tournament, tournament_schema)
    |> Multi.insert(:group_topic, &create_topic(&1.tournament, "Group", 0))
    |> Multi.insert(:notification_topic, &create_topic(&1.tournament, "Notification", 1, 1))
    |> Multi.insert(:q_and_a_topic, &create_topic(&1.tournament, "Q&A", 2))
    |> Repo.transaction()
    |> case do
      {:ok, result} -> {:ok, result.tournament}
      {:error, :tournament, changeset, _} -> {:error, Tools.create_error_message(changeset.errors)}
      {:error, changeset} -> {:error, changeset.errors}
      _ -> {:error, nil}
    end
  end

  # TODO: トランザクション
  @spec join_chat_topics_on_create_tournament(Tournament.t()) :: {:ok, nil} | {:error, String.t()}
  defp join_chat_topics_on_create_tournament(tournament) do
    tournament.id
    |> Chat.get_chat_rooms_by_tournament_id()
    |> Enum.all?(fn chat_room ->
      %{
        "user_id" => tournament.master_id,
        "authority" => 1,
        "chat_room_id" => chat_room.id
      }
      |> Chat.create_chat_member()
      |> elem(0)
      |> Kernel.==(:ok)
    end)
    |> if do
      {:ok, nil}
    else
      {:error, "failed to join chat topics"}
    end
  end

  @spec add_necessary_fields(Tournament.t(), map()) :: {:ok, nil} | {:error, String.t()}
  defp add_necessary_fields(%Tournament{rule: rule} = tournament, attrs) do
    case rule do
      "flipban" -> add_flipban_fields(tournament, attrs)
      "basic" -> add_basic_fields(tournament, attrs)
      _ -> {:error, "invalid tournament rule"}
    end
  end

  @spec add_basic_fields(Tournament.t(), any()) :: {:ok, nil} | {:error, String.t()}
  defp add_basic_fields(tournament, _attrs) do
    tournament
    |> initialize_state_machine()
    |> case do
      :ok -> {:ok, nil}
      :error -> {:error, "failed to initialize state machine"}
    end
  end

  @spec add_flipban_fields(Tournament.t(), map()) :: {:ok, nil} | {:error, String.t()}
  defp add_flipban_fields(tournament, attrs) do
    with :ok <- initialize_state_machine(tournament),
         {:ok, _}  <- create_tournament_custom_detail_on_create_tournament(tournament, attrs) do
      create_maps_on_create_tournament(tournament, attrs)
    else
      :error -> {:error, "failed to initialize state machine"}
      errors -> errors
    end
  end

  @spec create_tournament_custom_detail_on_create_tournament(Tournament.t(), map()) :: {:ok, TournamentCustomDetail.t()} | {:error, Ecto.Changeset.t()}
  defp create_tournament_custom_detail_on_create_tournament(tournament, attrs) do
    attrs
    |> Map.put("tournament_id", tournament.id)
    |> __MODULE__.create_custom_detail()
  end

  # TODO: トランザクション
  @spec create_maps_on_create_tournament(Tournament.t(), [any()] | map() | nil) :: {:ok, nil} | {:error, String.t()}
  defp create_maps_on_create_tournament(tournament, maps) when is_list(maps) do
    maps
    |> Enum.all?(fn map ->
      map
      |> Map.put("tournament_id", tournament.id)
      |> __MODULE__.create_map()
      |> elem(0)
      |> Kernel.==(:ok)
    end)
    |> if do
      {:ok, nil}
    else
      {:error, "error on creating maps"}
    end
  end
  defp create_maps_on_create_tournament(tournament, %{maps: maps}), do: create_maps_on_create_tournament(tournament, %{"maps" => maps})
  defp create_maps_on_create_tournament(tournament, %{"maps" => maps}) when not is_nil(maps) do
    maps = Tools.parse_json_string_as_needed!(maps)
    create_maps_on_create_tournament(tournament, maps)
  end
  defp create_maps_on_create_tournament(_, _), do: {:error, "maps are nil"}

  @spec put_token_as_needed(map()) :: map()
  defp put_token_as_needed(%{"url" => nil} = attrs), do: attrs
  defp put_token_as_needed(%{"url" => ""} = attrs), do: attrs
  defp put_token_as_needed(%{"url" => url} = attrs) do
    url
    |> String.split("/")
    |> Enum.reverse()
    |> hd()
    ~> token

    Map.put(attrs, "url_token", token)
  end

  @spec create_topic(Tournament.t(), String.t(), integer(), integer()) :: Ecto.Changeset.t()
  defp create_topic(tournament, topic, tab_index, authority \\ 0) do
    {:ok, chat_room} =
      %{
        name: tournament.name <> "-" <> topic,
        member_count: tournament.count,
        authority: authority
      }
      |> Chat.create_chat_room()

    # NOTE: メンバー追加
    tournament.id
    |> Chat.get_uniq_chat_members_by_tournament_id()
    |> Enum.each(fn member ->
      Chat.create_chat_member(%{"user_id" => member.user_id, "chat_room_id" => chat_room.id})
    end)

    %TournamentChatTopic{tournament_id: tournament.id, chat_room_id: chat_room.id}
    |> TournamentChatTopic.changeset(%{"topic_name" => topic, "tab_index" => tab_index})
  end

  @doc """
  update tournament topics.
  TODO: エラーハンドリング
  """
  @spec update_topic(Tournament.t(), [TournamentChatTopic.t()], [map()]) :: :ok
  def update_topic(tournament, current_tabs, new_tabs) do
    current_ids = Enum.map(current_tabs, &(&1.chat_room_id))
    new_ids = Enum.map(new_tabs, &(&1["chat_room_id"]))

    removed_tab_ids = current_ids -- new_ids

    Enum.each(removed_tab_ids, fn id ->
      ChatRoom
      |> where([c], c.id == ^id)
      |> Repo.delete_all()
    end)

    Enum.each(new_tabs, fn tab ->
      if tab["chat_room_id"] do
        TournamentChatTopic
        |> where([c], c.chat_room_id == ^tab["chat_room_id"])
        |> Repo.one()
        ~> topic

        __MODULE__.update_tournament_chat_topic(topic, %{
          topic_name: tab["topic_name"],
          tab_index: tab["tab_index"]
        })
      else
        tournament
        |> create_topic(tab["topic_name"], tab["tab_index"])
        |> Repo.insert()
      end
    end)
  end

  @spec initialize_state_machine(Tournament.t()) :: :ok | :error
  defp initialize_state_machine(%Tournament{rule: rule, is_team: is_team}) do
    case rule do
      "basic" -> Basic.define_dfa!(is_team: is_team)
      "flipban" -> FlipBan.define_dfa!(is_team: is_team)
      _ -> :error
    end
  end

  @doc """
  Verify password.
  """
  @spec verify?(integer(), String.t()) :: boolean()
  def verify?(tournament_id, password) do
    tournament = get_tournament(tournament_id)
    Argon2.verify_pass(password, tournament.password)
  end

  @doc """
  Updates a tournament.

  ## Examples

      iex> update_tournament(tournament, %{field: new_value})
      {:ok, %Tournament{}}

      iex> update_tournament(tournament, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_tournament(Tournament.t(), map()) :: {:ok, Tournament.t()} | {:error, Ecto.Changeset.t() | nil}
  def update_tournament(tournament, attrs) do
    attrs
    |> Map.get("platform")
    |> is_nil()
    |> unless do
      Map.put(attrs, "platform_id", attrs["platform"])
    else
      attrs
    end
    ~> attrs

    if !attrs["game_id"] or Repo.exists?(from g in Game, where: g.id == ^attrs["game_id"]) do
      tournament
      |> Tournament.changeset(attrs)
      |> Repo.update()
      |> case do
        {:ok, tournament} ->
          update_details(tournament, attrs)
          {:ok, tournament}

        {:error, error} ->
          {:error, error.errors}

        _ ->
          {:error, nil}
      end
    else
      {:error, nil}
    end
  end

  @spec update_details(Tournament.t(), map()) :: {:ok, TournamentCustomDetail.t()} | {:error, Ecto.Changeset.t()}
  defp update_details(tournament, params) do
    params
    |> Map.put(:tournament_id, tournament.id)
    |> Tools.atom_map_to_string_map()
    ~> params

    tournament.id
    |> get_custom_detail_by_tournament_id()
    |> __MODULE__.update_custom_detail(params)
  end

  @doc """
  Flip coin request.
  """
  @spec flip_coin(integer(), integer()) :: boolean() | nil
  def flip_coin(user_id, tournament_id) do
    tournament = __MODULE__.get_tournament(tournament_id)
    id = Progress.get_necessary_id(tournament_id, user_id)

    Progress.insert_match_pending_list_table(id, tournament_id)

    if tournament.enabled_map do
      case tournament.rule do
        # NOTE: map_selection_typeで分岐もできる
        _ -> Progress.init_ban_order(tournament_id, id)
      end
    end
  end

  @doc """
  Ban a map.
  """
  @spec ban_maps(integer(), integer(), [integer()]) :: {:ok, nil} | {:error, String.t()}
  def ban_maps(user_id, _, _) when not is_integer(user_id), do: {:error, "user id should be integer"}
  def ban_maps(_, tournament_id, _) when not is_integer(tournament_id), do: {:error, "tournament id should be integer"}
  def ban_maps(_, _, map_id_list) when not is_list(map_id_list), do: {:error, "invalid map id list"}
  def ban_maps(user_id, tournament_id, map_id_list) do
    tournament_id
    |> __MODULE__.get_opponent(user_id)
    |> elem(1)
    |> Map.get(:id)
    ~> opponent_id

    tournament_id
    |> __MODULE__.state!(user_id)
    |> change_map_state(user_id, tournament_id, map_id_list, opponent_id, "banned")
    |> case do
      {:ok, _} -> renew_state_after_choosing_maps(user_id, tournament_id)
      {:error, error} -> {:error, error}
    end
  end

  defp change_map_state(state, _, _, _, _, _) when state != "ShouldBan" and state != "ShouldChooseMap", do: {:error, "invalid state"}
  defp change_map_state(_, _, _, _, opponent_id, _) when not is_integer(opponent_id), do: {:error, "opponent id is not integer"}
  defp change_map_state(_, user_id, tournament_id, map_id_list, opponent_id, map_state) do
    my_id = Progress.get_necessary_id(tournament_id, user_id)

    [small_id, large_id] = Enum.sort([my_id, opponent_id])

    map_id_list
    |> Enum.all?(fn map_id ->
      attrs = %{
        map_id: map_id,
        state: map_state,
        large_id: large_id,
        small_id: small_id
      }

      %MapSelection{}
      |> MapSelection.changeset(attrs)
      |> Repo.insert()
      ~> result

      match?({:ok, _}, result)
    end)
    |>  Tools.boolean_to_tuple("failed to ban maps")
  end

  @doc """
  Choose a map.
  """
  @spec choose_maps(integer(), integer(), [integer()]) :: {:ok, nil} | {:error, String.t()}
  def choose_maps(user_id, _, _) when not is_integer(user_id), do: {:error, "user id should be integer"}
  def choose_maps(_, tournament_id, _) when not is_integer(tournament_id), do: {:error, "tournament id should be integer"}
  def choose_maps(_, _, map_id_list) when not is_list(map_id_list), do: {:error, "invalid map id list"}
  def choose_maps(user_id, tournament_id, map_id_list) do
    tournament_id
    |> __MODULE__.get_opponent(user_id)
    |> elem(1)
    |> Map.get(:id)
    ~> opponent_id

    tournament_id
    |> __MODULE__.state!(user_id)
    |> change_map_state(user_id, tournament_id, map_id_list, opponent_id, "selected")
    |> case do
      {:ok, _} -> renew_state_after_choosing_maps(user_id, tournament_id)
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Choose A/D
  """
  @spec choose_ad(integer(), integer(), boolean()) :: {:ok, nil} | {:error, String.t()}
  def choose_ad(user_id, _, _) when not is_integer(user_id), do: {:error, "user id should be integer"}
  def choose_ad(_, tournament_id, _) when not is_integer(tournament_id), do: {:error, "tournament id should be integer"}
  def choose_ad(_, _, is_attacker_side) when not is_boolean(is_attacker_side), do: {:error, "attacker side information should be boolean"}
  def choose_ad(user_id, tournament_id, is_attack_side) do
    tournament_id
    |> __MODULE__.get_opponent(user_id)
    |> elem(1)
    |> Map.get(:id)
    ~> opponent_id

    tournament_id
    |> __MODULE__.state!(user_id)
    |> do_choose_ad(user_id, tournament_id, opponent_id, is_attack_side)
    |> case do
      {:ok, nil} -> renew_state_after_choosing_maps(user_id, tournament_id)
      {:error, error} -> {:error, error}
    end
  end

  defp do_choose_ad(state, _, _, _, _) when state != "ShouldChooseA/D", do: {:error, "invalid state"}
  defp do_choose_ad(_, _, _, opponent_id, _) when not is_integer(opponent_id), do: {:error, "opponent id is not integer"}
  defp do_choose_ad(_, user_id, tournament_id, opponent_id, is_attacker_side) do
    my_id = Progress.get_necessary_id(tournament_id, user_id)

    has_me_inserted = Progress.insert_is_attacker_side(my_id, tournament_id, is_attacker_side)
    has_opponent_inserted = Progress.insert_is_attacker_side(opponent_id, tournament_id, !is_attacker_side)

    if has_me_inserted && has_opponent_inserted do
      {:ok, nil}
    else
      {:error, "failed to insert is_attacker_side"}
    end
  end

  @spec renew_state_after_choosing_maps(integer(), integer()) :: {:ok, nil}
  defp renew_state_after_choosing_maps(user_id, tournament_id) do
    id = Progress.get_necessary_id(tournament_id, user_id)

    {:ok, opponent} = __MODULE__.get_opponent(tournament_id, user_id)

    order = Progress.get_ban_order(tournament_id, id)
    opponent_order = Progress.get_ban_order(tournament_id, opponent.id)
    Progress.delete_ban_order(tournament_id, id)
    Progress.delete_ban_order(tournament_id, opponent.id)
    Progress.insert_ban_order(tournament_id, id, order + 1)
    Progress.insert_ban_order(tournament_id, opponent.id, opponent_order + 1)

    {:ok, nil}
  end

  @doc """
  Deletes a tournament.

  ## Examples

      iex> delete_tournament(tournament)
      {:ok, %Tournament{}}

      iex> delete_tournament(tournament)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_tournament(Tournament.t() | map() | integer()) :: {:ok, Tournament.t()} | {:error, Ecto.Changeset.t() | String.t()}
  def delete_tournament(nil), do: {:error, "tournament is nil"}
  def delete_tournament(%Tournament{id: id}), do: delete_tournament(id)
  def delete_tournament(%{"id" => id}), do: delete_tournament(id)

  def delete_tournament(id) when is_integer(id) do
    # tournament =
    #   Repo.one(
    #     from t in Tournament,
    #       left_join: a in assoc(t, :assistant),
    #       left_join: e in assoc(t, :entrant),
    #       where: t.id == ^id,
    #       preload: [assistant: a, entrant: e]
    #   )
    Tournament
    |> join(:left, [t], a in assoc(t, :assistant))
    |> join(:left, [t, a], e in assoc(t, :entrant))
    |> where([t, a, e], t.id == ^id)
    |> preload([t, a, e], [assistant: a, entrant: e])
    |> Repo.one()
    ~> tournament

    entrants =
      Enum.map(tournament.entrant, fn x ->
        %{
          rank: x.rank,
          user_id: x.user_id,
          tournament_id: x.tournament_id,
          update_time: x.update_time,
          create_time: x.create_time
        }
      end)

    unless entrants == [], do: Repo.insert_all(EntrantLog, entrants)

    assistants =
      Enum.map(tournament.assistant, fn x ->
        %{
          user_id: x.user_id,
          tournament_id: x.tournament_id,
          update_time: x.update_time,
          create_time: x.create_time
        }
      end)

    unless assistants == [], do: Repo.insert_all(AssistantLog, assistants)

    Repo.delete(tournament)
  end

  @doc """
  Gets a single entrant.
  """
  @spec get_entrant(integer()) :: Entrant.t() | nil
  def get_entrant(id), do: Repo.get(Entrant, id)

  @doc """
  Get entrants of a tournament.
  """
  @spec get_entrants(integer()) :: [Entrant.t()]
  def get_entrants(tournament_id) do
    Entrant
    |> where([e], e.tournament_id == ^tournament_id)
    |> Repo.all()
  end

  @doc """
  Get a single entrant or log.
  """
  @spec get_entrant_including_logs(integer()) :: Entrant.t() | EntrantLog.t() | nil
  def get_entrant_including_logs(id) do
    case __MODULE__.get_entrant(id) do
      nil -> Log.get_entrant_log_by_entrant_id(id)
      entrant -> entrant
    end
  end

  @spec get_entrant_including_logs(integer(), integer()) :: Entrant.t() | EntrantLog.t() | nil
  def get_entrant_including_logs(tournament_id, user_id) do
    case get_entrant_by_user_id_and_tournament_id(user_id, tournament_id) do
      nil -> Log.get_entrant_log_by_user_id_and_tournament_id(user_id, tournament_id)
      entrant -> entrant
    end
  end

  @spec get_entrant_by_user_id_and_tournament_id(integer(), integer()) :: Entrant.t() | nil
  defp get_entrant_by_user_id_and_tournament_id(user_id, tournament_id) do
    Entrant
    |> where([e], e.tournament_id == ^tournament_id)
    |> where([e], e.user_id == ^user_id)
    |> Repo.one()
  end

  @doc """
  Creates an entrant.
  """
  @spec create_entrant(map()) :: {:ok, Entrant.t()} | {:error, Ecto.Changeset.t() | String.t() | nil}
  def create_entrant(attrs) do
    with {:ok, nil} <- validate_user_id(attrs),
         {:ok, attrs} <- validate_tournament_id(attrs),
         {:ok, nil} <- validate_not_team_tournament(attrs),
         {:ok, nil} <- validate_not_participated_yet(attrs),
         {:ok, nil} <- validate_tournament_size(attrs),
         {:ok, entrant} <- do_create_entrant(attrs),
         {:ok, nil} <- join_chat_topics_on_create_entrant(entrant) do
      {:ok, entrant}
    else
      error -> error
    end
  end

  @spec validate_user_id(map()) :: {:ok, nil} | {:error, String.t()}
  defp validate_user_id(%{"user_id" => nil}), do: {:error, "user id is nil"}
  defp validate_user_id(%{"user_id" => user_id}) do
    User
    |> where([u], u.id == ^user_id)
    |> Repo.exists?()
    |> if do
      {:ok, nil}
    else
      {:error, "undefined user"}
    end
  end
  defp validate_user_id(_), do: {:error, "invalid attrs"}

  @spec validate_tournament_id(map()) :: {:ok, map()} | {:error, String.t()}
  defp validate_tournament_id(%{"tournament_id" => nil}), do: {:error, "tournament id is nil"}
  defp validate_tournament_id(%{"tournament_id" => tournament_id} = attrs) do
    tournament_id
    |> __MODULE__.get_tournament()
    |> put_tournament_into_attrs(attrs)
  end
  defp validate_tournament_id(_), do: {:error, "invalid attrs"}

  @spec put_tournament_into_attrs(Tournament.t() | nil, map()) :: {:ok, map()} | {:error, String.t()}
  defp put_tournament_into_attrs(nil, _), do: {:error, "undefined tournament"}
  defp put_tournament_into_attrs(tournament, attrs), do: {:ok, Map.put(attrs, "tournament", tournament)}

  @spec validate_not_team_tournament(map()) :: {:ok, nil} | {:error, String.t()}
  defp validate_not_team_tournament(%{"tournament" => %Tournament{is_team: true}}), do: {:error, "requires team"}
  defp validate_not_team_tournament(_), do: {:ok, nil}

  @spec validate_not_participated_yet(map()) :: {:ok, nil} | {:error, String.t()}
  defp validate_not_participated_yet(%{"tournament_id" => tournament_id, "user_id" => user_id}) do
    Entrant
    |> where([e], e.tournament_id == ^tournament_id)
    |> where([e], e.user_id == ^user_id)
    |> Repo.exists?()
    |> if do
      {:error, "already joined"}
    else
      {:ok, nil}
    end
  end

  @spec validate_tournament_size(map()) :: {:ok, nil} | {:error, String.t()}
  defp validate_tournament_size(%{"tournament" => %Tournament{capacity: capacity, count: count}}) when capacity > count, do: {:ok, nil}
  defp validate_tournament_size(_), do: {:error, "capacity over"}

  @spec do_create_entrant(map()) :: {:ok, Entrant.t()} | {:error, String.t()}
  defp do_create_entrant(%{"user_id" => user_id, "tournament_id" => tournament_id, "tournament" => tournament} = attrs) do
    user_id = Tools.to_integer_as_needed(user_id)
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    entrant = %Entrant{
      user_id: user_id,
      tournament_id: tournament_id
    }

    Multi.new()
    |> Multi.put(:attrs, attrs)
    |> Multi.put(:tournament, tournament)
    |> Multi.insert(:entrant, &Entrant.changeset(entrant, &1.attrs))
    |> Multi.update(:update, &Tournament.changeset(&1.tournament, %{count: &1.tournament.count + 1}))
    |> Repo.transaction()
    |> case do
      {:ok, result} -> {:ok, result.entrant}
      {:error, :tournament, changeset, _} -> {:error, Tools.create_error_message(changeset.errors)}
      {:error, changeset} -> {:error, changeset.errors}
      _ -> {:error, nil}
    end
  end

  @spec join_chat_topics_on_create_entrant(Entrant.t()) :: {:ok, nil}
  defp join_chat_topics_on_create_entrant(%Entrant{user_id: user_id, tournament_id: tournament_id}) do
    tournament_id
    |> Chat.get_chat_rooms_by_tournament_id()
    |> Enum.each(fn chat_room ->
      Chat.create_chat_member(%{
        "user_id" => user_id,
        "chat_room_id" => chat_room.id,
        "authority" => 0
      })
    end)
    {:ok, nil}
  end

  defp user_exists?(%{"user_id" => user_id} = attrs) when not is_nil(user_id) do
    User
    |> where([u], u.id == ^attrs["user_id"])
    |> Repo.exists?()
    |> if do
      {:ok, attrs}
    else
      {:error, "undefined user"}
    end
  end

  defp user_exists?(_), do: {:error, "invalid attrs"}

  defp tournament_exists?({:ok, attrs}) do
    tournament = get_tournament(attrs["tournament_id"])

    if tournament do
      attrs = Map.put(attrs, "tournament", tournament)
      {:ok, attrs}
    else
      {:error, "undefined tournament"}
    end
  end

  defp tournament_exists?({:error, error}) do
    {:error, error}
  end

  @doc """
  Updates a entrant.

  ## Examples

      iex> update_entrant(entrant, %{field: new_value})
      {:ok, %Entrant{}}

      iex> update_entrant(entrant, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_entrant(Entrant.t(), map()) :: {:ok, Entrant.t()} | {:error, Ecto.Changeset.t() | nil}
  def update_entrant(nil, _), do: {:error, "entrant is nil"}
  def update_entrant(%Entrant{} = entrant, attrs) do
    entrant
    |> Entrant.changeset(attrs)
    |> Repo.update()
  end

  @spec update_entrant(integer(), integer(), map()) :: {:ok, Entrant.t()} | {:error, Ecto.Changeset.t() | nil}
  def update_entrant(tournament_id, user_id, attrs) do
    user_id
    |> get_entrant_by_user_id_and_tournament_id(tournament_id)
    |> __MODULE__.update_entrant(attrs)
  end

  @doc """
  Deletes a entrant.

  ## Examples

      iex> delete_entrant(entrant)
      {:ok, %Entrant{}}

      iex> delete_entrant(entrant)
      {:error, %Ecto.Changeset{}}
  """
  @spec delete_entrant(integer(), integer()) :: {:ok, Entrant.t()} | {:error, String.t() | Ecto.Changeset.t() | nil}
  def delete_entrant(tournament_id, user_id) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    user_id = Tools.to_integer_as_needed(user_id)

    unless Repo.exists?(from e in Entrant, where: e.tournament_id == ^tournament_id and e.user_id == ^user_id) do
      {:error, "entrant not found"}
    else
      entrant =
        Entrant
        |> where([e], e.tournament_id == ^tournament_id and e.user_id == ^user_id)
        |> Repo.one()

      delete_entrant(entrant)

      get_tabs_including_logs_by_tourament_id(tournament_id)
      |> Enum.each(fn x ->
        x.chat_room_id
        |> Chat.delete_chat_member(user_id)
      end)

      {:ok, entrant}
    end
  end

  @spec delete_entrant(Entrant.t()) :: {:ok, Entrant.t()} | {:error, Ecto.Changeset.t()}
  def delete_entrant(nil), do: {:error, "entrant is nil"}
  def delete_entrant(%Entrant{} = entrant) do
    # map =
    #   entrant
    #   |> Map.from_struct()
    #   |> Map.put(:entrant_id, entrant.id)

    # %EntrantLog{}
    # |> EntrantLog.changeset(map)
    # |> Repo.insert()

    tournament = Repo.get(Tournament, entrant.tournament_id)

    Tournament.changeset(tournament, %{count: tournament.count - 1})
    |> Repo.update()

    Repo.delete(entrant)
  end

  @doc """
  Get a rank of a user.
  """
  @spec get_rank(integer(), integer()) :: {:ok, integer() | nil} | {:error, String.t()}
  def get_rank(tournament_id, user_id) do
    tournament_id
    |> get_entrant_including_logs(user_id)
    ~> entrant
    |> if do
      {:ok, entrant.rank}
    else
      {:error, "entrant is not found"}
    end
  end

  @doc """
  Delete loser.
  TODO: エラーハンドリング
  loser_listは一人用
  """
  @spec delete_loser_process(integer(), [integer()]) :: [any()]
  def delete_loser_process(tournament_id, loser_list) when is_list(loser_list) do
    match_list = Progress.get_match_list(tournament_id)

    match_list
    |> find_match(hd(loser_list))
    |> Enum.each(fn user_id ->
      if is_integer(user_id) do
        Progress.delete_match_pending_list(user_id, tournament_id)
        Progress.delete_fight_result(user_id, tournament_id)
      end
    end)

    renew_match_list(tournament_id, match_list, loser_list)
    updated_match_list = Progress.get_match_list(tournament_id)
    renew_match_list_with_fight_result(tournament_id, loser_list)

    updated_match_list
  end

  defp renew_match_list_with_fight_result(tournament_id, [loser]) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    Progress.renew_match_list_with_fight_result(loser, tournament_id)
  end

  defp renew_match_list(tournament_id, match_list, loser_list) do
    unless match_list == [] do
      promote_winners_by_loser!(tournament_id, match_list, loser_list)
    end

    renew(loser_list, tournament_id)
  end

  defp renew(loser_list, tournament_id) do
    loser_list
    |> Progress.renew_match_list(tournament_id)
    |> unless do
      Process.sleep(100)
      renew(loser_list, tournament_id)
    end
  end

  @doc """
  Delete a loser in a matchlist
  """
  @spec delete_loser(match_list(), integer() | [integer()]) :: [any()]
  def delete_loser(match_list, loser) do
    Tournamex.delete_loser(match_list, loser)
  end

  @doc """
  Promote winners
  """
  @spec promote_winners_by_loser!(integer(), match_list(), [integer()] | integer()) :: {:ok, [any()]} | {:error, String.t() | nil}
  def promote_winners_by_loser!(tournament_id, match_list, losers) when is_list(losers) do
    Enum.map(losers, fn loser ->
      match_list
      |> find_match(loser)
      |> case do
        [] ->
          {:error, nil}

        _match ->
          tournament = __MODULE__.get_tournament(tournament_id)

          if tournament.is_team do
            loser
            |> __MODULE__.get_leader()
            |> Map.get(:user_id)
          else
            loser
          end
          ~> loser_id

          tournament_id
          |> __MODULE__.get_opponent(loser_id)
          |> case do
            {:ok, opponent} -> {:ok, opponent, tournament}
            {:wait, nil} -> {:wait, nil, tournament}
            _ -> {:error, nil}
          end
      end
      |> case do
        {:ok, opponent, tournament} ->
          if tournament.is_team do
            Map.new()
            |> Map.put("tournament_id", tournament_id)
            |> Map.put("team_id", opponent.id)
            |> promote_rank()
          else
            Map.new()
            |> Map.put("tournament_id", tournament_id)
            |> Map.put("user_id", opponent.id)
            |> promote_rank()
          end

        {:wait, nil, _} ->
          {:wait, nil, nil}

        {:error, nil} ->
          {:error, nil}
      end
    end)
  end

  def promote_winners_by_loser!(tournament_id, match_list, loser) do
    match_list
    |> find_match(loser)
    |> Kernel.==([])
    |> unless do
      tournament_id
      |> __MODULE__.get_opponent(loser)
      |> case do
        {:ok, opponent} ->
          promote_rank(%{"tournament_id" => tournament_id, "user_id" => opponent.id})

        {:wait, nil} ->
          raise RuntimeError, "Expected {:ok, opponent}, got: {:wait, nil}"

        _ ->
          raise RuntimeError, "Unexpected Output"
      end
    end
  end

  @doc """
  Finds a 1v1 match of given id and match list.
  """
  @spec find_match(integer() | match_list(), any()) :: [any()]
  def find_match(v, _) when is_integer(v), do: []

  @spec find_match(match_list(), integer(), [any()]) :: [any()]
  def find_match(match_list, id, result \\ []) when is_list(match_list) do
    Enum.reduce(match_list, result, fn x, acc ->
      y = pick_user_id_as_needed(x)

      case y do
        y when is_list(y) -> find_match(y, id, acc)
        y when is_integer(y) and y == id -> acc ++ match_list
        y when is_integer(y) -> acc
      end
    end)
  end

  defp pick_user_id_as_needed(%Entrant{} = map) do
    inspect(map, charlists: false)
    map.user_id
  end

  defp pick_user_id_as_needed(id), do: id

  @doc """
  Get an opponent.
  """
  @spec get_opponent(integer(), integer()) ::
          {:ok, User.t()} | {:ok, Team.t()} | {:wait, nil} | {:error, String.t()}
  def get_opponent(tournament_id, user_id) do
    tournament_id
    |> __MODULE__.get_tournament()
    |> get_opponent_if_started(user_id)
  end

  defp get_opponent_if_started(nil, _), do: {:error, "tournament is nil"}

  defp get_opponent_if_started(%Tournament{is_started: false}, _), do: {:error, "tournament is not started"}
  defp get_opponent_if_started(%Tournament{is_team: true, id: id}, user_id) do
    id
    |> __MODULE__.get_team_by_tournament_id_and_user_id(user_id)
    |> get_opponent_team_if_started()
  end
  defp get_opponent_if_started(%Tournament{id: id}, user_id) do
    id
    |> Progress.get_match_list()
    |> __MODULE__.find_match(user_id)
    |> get_opponent_user(user_id)
  end

  defp get_opponent_team_if_started(nil), do: {:error, "team is nil"}
  defp get_opponent_team_if_started(%Team{id: id, tournament_id: tournament_id}) do
    tournament_id
    |> Progress.get_match_list()
    |> __MODULE__.find_match(id)
    |> get_opponent_team(id)
  end

  @spec get_opponent_user([any()], integer()) :: {:ok, User.t()} | {:wait, nil} | {:error, String.t()}
  defp get_opponent_user(match, user_id) do
    if Enum.member?(match, user_id) and length(match) == 2 do
      match
      |> Enum.filter(&(&1 != user_id))
      |> hd()
      |> do_get_opponent_user()
    else
      {:error, "opponent does not exist"}
    end
  end

  @spec do_get_opponent_user(integer()) :: {:ok, User.t()} | {:wait, nil} | {:error, String.t()}
  defp do_get_opponent_user(opponent_id) when is_integer(opponent_id) do
    {:ok, Accounts.get_user(opponent_id)}
  end

  defp do_get_opponent_user(_), do: {:wait, nil}

  @spec get_opponent_team([any()], integer()) :: {:ok, Team.t()} | {:wait, nil} | {:error, String.t()}
  defp get_opponent_team(match, team_id) do
    if Enum.member?(match, team_id) and length(match) == 2 do
      match
      |> Enum.filter(&(&1 != team_id))
      |> hd()
      |> do_get_opponent_team()
    else
      {:error, "opponent team does not exist"}
    end
  end

  @spec do_get_opponent_team(integer()) :: {:ok, Team.t()} | {:wait, nil} | {:error, String.t()}
  defp do_get_opponent_team(opponent_team_id) when is_integer(opponent_team_id) do
    {:ok, __MODULE__.get_team(opponent_team_id)}
  end

  defp do_get_opponent_team(_), do: {:wait, nil}

  @doc """
  Checks whether the user have to wait.
  """
  @spec is_alone?([any()]) :: boolean()
  def is_alone?(match) do
    Enum.filter(match, &is_list(&1)) != []
  end

  @doc """
  Checks whether the user has already lost.
  """
  @spec has_lost?(integer() | match_list(), integer()) :: boolean()
  def has_lost?(v, _) when is_integer(v), do: false

  @spec has_lost?(match_list(), integer(), boolean()) :: boolean()
  def has_lost?(match_list, user_id, result \\ true) when is_list(match_list) do
    Enum.reduce(match_list, result, fn x, acc ->
      case x do
        x when is_list(x) -> has_lost?(x, user_id, acc)
        x when x == user_id -> false
        _ -> acc
      end
    end)
  end

  @doc """
  Starts a tournament.

  1. load tournament information
  2. check whether entrant number goes over the caoacity
  3. start tournament
  4. initialize a state machine of participants
  """
  @spec start(integer(), integer()) :: {:ok, Tournament.t()} | {:error, Ecto.Changeset.t()} | {:error, String.t()}
  def start(tournament_id, master_id) when is_nil(master_id) or is_nil(tournament_id), do: {:error, "master_id or tournament_id is nil"}
  def start(tournament_id, master_id) do
    with {:ok, %Tournament{} = tournament} <- load_tournament(tournament_id, master_id),
         {:ok, nil} <- validate_entrant_number(tournament),
         {:ok, tournament} <- start(tournament),
         {:ok, tournament} <- initialize_participant_states!(tournament) do
      {:ok, tournament}
    else
      error -> error
    end
  end

  @spec load_tournament(integer(), integer()) :: {:ok, Tournament.t()} | {:error, String.t()}
  defp load_tournament(tournament_id, master_id) when is_nil(master_id) or is_nil(tournament_id), do: {:error, "master_id or tournament_id is nil"}
  defp load_tournament(tournament_id, master_id) do
    Tournament
    |> where([t], t.master_id == ^master_id)
    |> where([t], t.id == ^tournament_id)
    |> Repo.one()
    |> load_tournament()
  end

  @spec load_tournament(Tournament.t() | nil) :: {:ok, Tournament.t()} | {:error, String.t()}
  defp load_tournament(nil), do: {:error, "cannot find tournament"}
  defp load_tournament(tournament), do: {:ok, tournament}

  @spec validate_entrant_number(Tournament.t() | nil | integer()) :: {:ok, nil} | {:error, String.t()}
  defp validate_entrant_number(%Tournament{} = tournament) do
    Entrant
    |> where([e], e.tournament_id == ^tournament.id)
    |> Repo.aggregate(:count)
    |> validate_entrant_number()
  end

  defp validate_entrant_number(nil), do: {:error, "count is nil"}
  defp validate_entrant_number(num) when num <= 1, do: {:error, "short of participants"}
  defp validate_entrant_number(_), do: {:ok, nil}

  defp start(tournament) do
    if tournament.is_started do
      {:error, "tournament is already started"}
    else
      tournament
      |> Tournament.changeset(%{is_started: true})
      |> Repo.update()
    end
  end

  @spec initialize_participant_states!(Tournament.t()) :: {:ok, Tournament.t()}
  defp initialize_participant_states!(%Tournament{} = tournament) do
    tournament.id
    |> __MODULE__.get_entrants()
    |> Enum.each(fn entrant ->
      keyname = Rules.adapt_keyname(entrant.user_id)

      case tournament.rule do
        "basic" -> Basic.build_dfa_instance(keyname)
        "flipban" -> FlipBan.build_dfa_instance(keyname)
        _ -> raise "Invalid tournament rule"
      end
    end)

    {:ok, tournament}
  end

  @doc """
  Start a team tournament.
  """
  @spec start_team_tournament(integer(), integer()) :: {:ok, Tournament.t()} | {:error, Ecto.Changeset.t()} | {:error, String.t()}
  def start_team_tournament(tournament_id, master_id) when is_nil(tournament_id) or is_nil(master_id), do: {:error, "master_id or tournament_id is nil"}
  def start_team_tournament(tournament_id, master_id) do
    with {:ok, %Tournament{} = tournament} <- load_tournament(tournament_id, master_id),
         {:ok, nil} <- validate_team_number(tournament) do
      start(tournament)
    else
      error -> error
    end
  end

  defp validate_team_number(%Tournament{} = tournament) do
    tournament.id
    |> __MODULE__.get_confirmed_teams()
    |> length()
    |> validate_team_number()
  end

  defp validate_team_number(num) when num <= 1, do: {:error, "short of teams"}
  defp validate_team_number(_), do: {:ok, nil}

  @doc """
  Finish a tournament.
  トーナメントを終了させ、終了したトーナメントをログの方に移行して削除する
  """
  @spec finish(integer(), integer()) :: {:ok, Tournament.t()} | {:error, Ecto.Changeset.t() | String.t() | nil}
  def finish(tournament_id, winner_user_id) do
    tournament = __MODULE__.get_tournament(tournament_id)

    with {:ok, _} <- finish_participants(tournament),
         {:ok, _} <- finish_topics(tournament_id),
         {:ok, tournament} <- do_finish(tournament, winner_user_id) do
      {:ok, tournament}
    else
      error -> error
    end
  end

  @spec finish_participants(Tournament.t()) :: {:ok, nil} | {:error, String.t() | nil}
  defp finish_participants(%Tournament{is_team: false, id: tournament_id}) do
    tournament_id
    |> __MODULE__.get_entrants()
    |> Enum.all?(&({:ok, nil} == finish_entrant(&1)))
    |> Tools.boolean_to_tuple()
  end

  defp finish_participants(%Tournament{is_team: true, id: tournament_id}) do
    tournament_id
    |> __MODULE__.get_teams_by_tournament_id()
    |> Enum.all?(&({:ok, nil} == finish_team(&1)))
    |> Tools.boolean_to_tuple()
  end

  defp finish_entrant(%Entrant{} = entrant) do
    with {:ok, _} <- Log.create_entrant_log(entrant),
         {:ok, _} <- __MODULE__.delete_entrant(entrant) do
      {:ok, nil}
    else
      error -> error
    end
  end

  defp finish_team(%Team{} = team) do
    with {:ok, _} <- Log.create_team_log(team.id),
         {:ok, _} <- __MODULE__.delete_team(team) do
      {:ok, nil}
    else
      error -> error
    end
  end

  defp finish_topics(tournament_id) do
    tournament_id
    |> __MODULE__.get_tabs_by_tournament_id()
    |> Enum.all?(&match?({:ok, _}, finish_topic(&1)))
    |> Tools.boolean_to_tuple("failed to finish topics")
  end

  defp finish_topic(%TournamentChatTopic{} = topic) do
    topic
    |> Map.from_struct()
    |> Log.create_tournament_chat_topic_log()
  end

  defp do_finish(%Tournament{} = tournament, winner_user_id) do
    with {:ok, _} <- create_tournament_log_on_finish(tournament, winner_user_id),
         {:ok, tournament} <- __MODULE__.delete_tournament(tournament) do
      {:ok, tournament}
    else
      error -> error
    end
  end

  defp create_tournament_log_on_finish(tournament, winner_user_id) do
    tournament
    |> Map.from_struct()
    |> Map.put(:tournament_id, tournament.id)
    |> Map.put(:winner_id, winner_user_id)
    |> Tools.atom_map_to_string_map()
    |> Log.create_tournament_log()
  end

  @doc """
  Get lost a player.
  """
  @spec get_lost(match_list(), integer() | [integer()]) :: match_list()
  def get_lost(match_list, loser) do
    Tournamex.renew_match_list_with_loser(match_list, loser)
  end

  @doc """
  Generate a matchlist.
  """
  @spec generate_matchlist([integer()]) :: {:ok, match_list()} | {:error, String.t()}
  def generate_matchlist(list) do
    Tournamex.generate_matchlist(list)
  end

  @doc """
  Initialize fight result of match list.
  """
  @spec initialize_match_list_with_fight_result(match_list()) :: match_list_with_fight_result()
  def initialize_match_list_with_fight_result(match_list) do
    Tournamex.initialize_match_list_with_fight_result(match_list)
  end

  @doc """
  Initialize fight result of match list of teams.
  """
  @spec initialize_match_list_of_team_with_fight_result(match_list()) ::
          match_list_with_fight_result()
  def initialize_match_list_of_team_with_fight_result(match_list) do
    Tournamex.initialize_match_list_of_team_with_fight_result(match_list)
  end

  @doc """
  Put value on brackets.
  """
  @spec put_value_on_brackets(match_list(), integer() | String.t() | atom(), any()) ::
          match_list() | match_list_with_fight_result()
  def put_value_on_brackets(match_list, key, value) do
    Tournamex.put_value_on_brackets(match_list, key, value)
  end

  @doc """
  Gets a single assistant.
  """
  @spec get_assistant(integer()) :: Assistant.t() | nil
  def get_assistant(id), do: Repo.get(Assistant, id)

  @spec get_assistants(integer()) :: [Assistant.t()]
  def get_assistants(tournament_id) do
    Assistant
    |> where([a], a.tournament_id == ^tournament_id)
    |> Repo.all()
  end

  @spec get_assistants_by_user_id(integer()) :: [Assistant.t()]
  def get_assistants_by_user_id(user_id) do
    Assistant
    |> where([a], a.user_id == ^user_id)
    |> Repo.all()
  end

  @doc """
  Get user information of an assistant.
  """
  @spec get_user_info_of_assistant(Assistant.t()) :: User.t() | nil
  def get_user_info_of_assistant(%Assistant{} = assistant) do
    User
    |> where([u], u.id == ^assistant.user_id)
    |> Repo.one()
  end

  @doc """
  Get fighting users.
  HACK: usersと書いてあるがチームを扱う場合もある
  """
  @spec get_fighting_users(integer()) :: [User.t()] | [Team.t()]
  def get_fighting_users(tournament_id) do
    tournament_id
    |> get_tournament()
    |> Map.get(:is_team)
    |> if do
      tournament_id
      |> get_confirmed_teams()
      |> Enum.filter(fn team ->
        team.id
        |> Progress.get_match_pending_list(tournament_id)
        |> Kernel.!=([])
      end)
    else
      tournament_id
      |> get_entrants()
      |> Enum.filter(fn entrant ->
        Progress.get_match_pending_list(entrant.user_id, tournament_id) != []
      end)
      |> Enum.map(fn entrant ->
        Accounts.get_user(entrant.user_id)
      end)
    end
  end

  @doc """
  Get users waiting for fighting ones.
  HACK: usersと書いてあるがチームを扱う場合もある
  """
  @spec get_waiting_users(integer()) :: [User.t()] | [Team.t()]
  def get_waiting_users(tournament_id) do
    tournament_id
    |> get_tournament()
    |> Map.get(:is_team)
    |> if do
      fighting_users = get_fighting_users(tournament_id)

      tournament_id
      |> get_confirmed_teams()
      |> Enum.filter(fn team ->
        tournament_id
        |> Progress.get_match_list()
        |> List.flatten()
        ~> flatten_match_list

        team.id in flatten_match_list and !Enum.member?(fighting_users, team)
      end)
    else
      fighting_users = get_fighting_users(tournament_id)

      tournament_id
      |> get_entrants()
      |> Enum.filter(fn entrant ->
        match_list = Progress.get_match_list(tournament_id)
        !has_lost?(match_list, entrant.user_id)
      end)
      |> Enum.map(fn entrant ->
        Accounts.get_user(entrant.user_id)
      end)
      |> Enum.filter(fn user ->
        # match_pending_listに入っていないユーザー
        !Enum.member?(fighting_users, user)
      end)
    end
  end

  @doc """
  Creates a assistant.

  ## Examples

      iex> create_assistant(%{field: value})
      {:ok, %Assistant{}}

      iex> create_assistant(%{field: bad_value})
      {:error, %Ecto.Changeset{}}
  """
  @spec create_assistants(map()) :: {:ok, [integer()]} | {:error, :tournament_not_found}
  def create_assistants(attrs \\ %{}) do
    tournament_id = Tools.to_integer_as_needed(attrs["tournament_id"])

    Assistant
    |> where([a], a.tournament_id == ^tournament_id)
    |> Repo.delete_all()

    Tournament
    |> where([t], t.id == ^tournament_id)
    |> Repo.exists?()
    ~> tournament_exists?

    if tournament_exists? and !is_nil(attrs["user_id"]) do
      attrs["user_id"]
      |> Enum.map(&Tools.to_integer_as_needed(&1))
      |> Enum.uniq()
      |> Enum.reject(fn id ->
        User
        |> where([u], u.id == ^id)
        |> Repo.exists?()
        |> if do
          Repo.insert(%Assistant{user_id: id, tournament_id: tournament_id})
          true
        else
          false
        end
      end)
      ~> not_found_users

      {:ok, not_found_users}
    else
      {:error, :tournament_not_found}
    end
  end

  @doc """
  Gets a single tournament_chat_topic.

  Raises `Ecto.NoResultsError` if the Tournament chat topic does not exist.

  ## Examples

      iex> get_tournament_chat_topic!(123)
      %TournamentChatTopic{}

      iex> get_tournament_chat_topic!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_tournament_chat_topic!(integer()) :: TournamentChatTopic.t()
  def get_tournament_chat_topic!(id), do: Repo.get!(TournamentChatTopic, id)

  @spec get_tabs_by_tournament_id(integer()) :: [TournamentChatTopic.t()]
  def get_tabs_by_tournament_id(tournament_id) do
    TournamentChatTopic
    |> where([t], t.tournament_id == ^tournament_id)
    |> Repo.all()
  end

  @doc """
  Get group chat tabs in a tournament including log.
  """
  @spec get_tabs_including_logs_by_tourament_id(integer()) :: [TournamentChatTopic.t() | TournamentChatTopicLog.t()]
  def get_tabs_including_logs_by_tourament_id(tournament_id) do
    topics = __MODULE__.get_tabs_by_tournament_id(tournament_id)

    TournamentChatTopicLog
    |> where([tl], tl.tournament_id == ^tournament_id)
    |> Repo.all()
    ~> logs

    topics ++ logs
  end

  @doc """
  Creates a tournament_chat_topic.

  ## Examples

      iex> create_tournament_chat_topic(%{field: value})
      {:ok, %TournamentChatTopic{}}

      iex> create_tournament_chat_topic(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_tournament_chat_topic(map()) :: {:ok, TournamentChatTopic.t()} | {:error, Ecto.Changeset.t()}
  def create_tournament_chat_topic(attrs \\ %{}) do
    %TournamentChatTopic{}
    |> TournamentChatTopic.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, topic} ->
        {:ok, Map.put(topic, :tournament_id, attrs["tournament_id"])}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Updates a tournament_chat_topic.

  ## Examples

      iex> update_tournament_chat_topic(tournament_chat_topic, %{field: new_value})
      {:ok, %TournamentChatTopic{}}

      iex> update_tournament_chat_topic(tournament_chat_topic, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_tournament_chat_topic(TournamentChatTopic.t(), map()) ::
          {:ok, TournamentChatTopic.t()} | {:error, Ecto.Changeset.t()}
  def update_tournament_chat_topic(%TournamentChatTopic{} = tournament_chat_topic, attrs) do
    tournament_chat_topic
    |> TournamentChatTopic.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a tournament_chat_topic.

  ## Examples

      iex> delete_tournament_chat_topic(tournament_chat_topic)
      {:ok, %TournamentChatTopic{}}

      iex> delete_tournament_chat_topic(tournament_chat_topic)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_tournament_chat_topic(TournamentChatTopic.t()) :: {:ok, TournamentChatTopic.t()} | {:error, Ecto.Changeset.t()}
  def delete_tournament_chat_topic(%TournamentChatTopic{} = tournament_chat_topic) do
    Repo.delete(tournament_chat_topic)
  end

  @doc """
  Force to promote rank
  """
  @spec force_to_promote_rank(map()) :: {:ok, Entrant.t() | Team.t()} | {:error, Ecto.Changeset.t() | String.t() | nil}
  def force_to_promote_rank(%{"user_id" => user_id, "tournament_id" => tournament_id} = attrs) do
    with {:ok, nil} <- validate_user_id(attrs),
         {:ok, attrs} <- validate_tournament_id(attrs),
         {:ok, nil} <- validate_tournament_started(attrs),
         {:ok, next_rank} <- find_next_rank(attrs),
         {:ok, entrant} <- __MODULE__.update_entrant(tournament_id, user_id, %{rank: next_rank}) do
      {:ok, entrant}
    else
      error -> error
    end
  end

  def force_to_promote_rank(%{"team_id" => team_id} = attrs) do
    with {:ok, nil} <- validate_team_id(attrs),
         {:ok, attrs} <- validate_tournament_id(attrs),
         {:ok, nil} <- validate_tournament_started(attrs),
         {:ok, next_rank} <- find_next_rank(attrs),
         {:ok, team} <- __MODULE__.update_team(team_id, %{rank: next_rank}) do
      {:ok, team}
    else
      error -> error
    end
  end

  defp validate_team_id(%{"team_id" => nil}), do: {:error, "team id is nil"}
  defp validate_team_id(%{"team_id" => team_id}) do
    Team
    |> where([t], t.id == ^team_id)
    |> Repo.exists?()
    |> if do
      {:ok, nil}
    else
      {:error, "undefined team"}
    end
  end
  defp validate_team_id(_), do: {:error, "invalid attrs"}

  defp validate_tournament_started(%{"tournament" => %Tournament{is_started: true}}), do: {:ok, nil}
  defp validate_tournament_started(_), do: {:error, "tournament is not started"}

  @spec find_next_rank(map()) :: {:ok, integer()}
  defp find_next_rank(%{"user_id" => user_id, "tournament_id" => tournament_id}) do
    user_id
    |> get_entrant_by_user_id_and_tournament_id(tournament_id)
    |> Map.get(:rank)
    |> calculate_next_rank()
    |> Tools.into_ok_tuple()
  end

  defp find_next_rank(%{"team_id" => team_id}) do
    team_id
    |> __MODULE__.get_team()
    |> Map.get(:rank)
    |> calculate_next_rank()
    |> Tools.into_ok_tuple()
  end

  @spec calculate_next_rank(integer()) :: integer()
  defp calculate_next_rank(0), do: 1
  defp calculate_next_rank(1), do: 1
  defp calculate_next_rank(rank) when is_power_of_two?(rank), do: div(rank, 2)
  defp calculate_next_rank(rank) when rank <= 4, do: 2

  @spec calculate_next_rank(integer(), integer()) :: integer()
  defp calculate_next_rank(rank, next_min \\ 8)
  defp calculate_next_rank(rank, next_min) when rank <= next_min, do: div(next_min, 2)
  defp calculate_next_rank(rank, next_min), do: calculate_next_rank(rank, next_min * 2)

  @doc """
  Promote rank
  """
  def promote_rank(%{"user_id" => user_id, "tournament_id" => tournament_id} = attrs) do
    attrs
    |> user_exists?()
    |> tournament_exists?()
    |> tournament_start_check()
    |> case do
      {:ok, _} ->
        get_match_list_if_possible(tournament_id)

      {:error, error} ->
        {:error, error}
    end
    |> case do
      {:ok, match_list} -> update_rank(match_list, user_id, tournament_id)
      {:error, error} -> {:error, error}
    end
  end

  def promote_rank(%{"team_id" => team_id, "tournament_id" => tournament_id} = attrs) do
    attrs
    |> team_exists?()
    |> tournament_exists?()
    |> tournament_start_check()
    |> case do
      {:ok, _} -> get_match_list_if_possible(tournament_id)
      {:error, error} -> {:error, error}
    end
    |> case do
      {:ok, match_list} -> update_team_rank(match_list, team_id, tournament_id)
      {:error, error} -> {:error, error}
    end
  end

  defp team_exists?(%{"team_id" => team_id} = attrs) do
    if Repo.exists?(from t in Team, where: t.id == ^team_id) do
      {:ok, attrs}
    else
      {:error, "undefined team"}
    end
  end

  defp get_match_list_if_possible(tournament_id) do
    tournament_id
    |> Progress.get_match_list()
    |> case do
      [] ->
        {:error, nil}

      match_list ->
        {:ok, match_list}
    end
  end

  defp update_rank(_match_list, user_id, tournament_id) do
    tournament_id
    |> __MODULE__.get_opponent(user_id)
    |> case do
      {:ok, opponent} ->
        opponent.id
        |> get_entrant_by_user_id_and_tournament_id(tournament_id)
        ~> opponent
        |> Map.get(:rank)
        ~> opponents_rank

        user_id
        |> get_entrant_by_user_id_and_tournament_id(tournament_id)
        ~> entrant
        |> Map.get(:rank)
        |> case do
          rank when rank > opponents_rank ->
            update_entrant(opponent, %{rank: rank})

          rank when rank < opponents_rank ->
            update_entrant(entrant, %{rank: opponents_rank})

          _ ->
            nil
        end

        opponent
        |> Map.get(:rank)
        |> check_exponentiation_of_two()
        ~> {_bool, rank}
        |> elem(0)
        |> if do
          div(rank, 2)
        else
          find_num_closest_exponentiation_of_two(rank)
        end
        ~> updated_rank

        user_id
        |> get_entrant_by_user_id_and_tournament_id(tournament_id)
        |> __MODULE__.update_entrant(%{rank: updated_rank})

      {:wait, nil} ->
        {:wait, nil}

      {:error, _} ->
        {:error, nil}
    end
  end

  defp update_team_rank(match_list, team_id, _tournament_id) do
    match_list
    |> find_match(team_id)
    |> get_opponent_team(team_id)
    |> case do
      {:ok, opponent} ->
        opponent
        |> Map.get(:id)
        |> get_team()
        ~> opponent_team
        |> Map.get(:rank)
        ~> opponent_team_rank

        team_id
        |> get_team()
        ~> team
        |> Map.get(:rank)
        |> case do
          rank when rank > opponent_team_rank ->
            update_team(opponent_team, %{rank: rank})

          rank when rank < opponent_team_rank ->
            update_team(team, %{rank: opponent_team_rank})

          _ ->
            nil
        end

        opponent_team
        |> Map.get(:rank)
        |> check_exponentiation_of_two()
        ~> {_bool, rank}
        |> elem(0)
        |> if do
          div(rank, 2)
        else
          find_num_closest_exponentiation_of_two(rank)
        end
        ~> updated_rank

        team_id
        |> get_team()
        |> update_team(%{rank: updated_rank})

      {:wait, nil} ->
        {:wait, nil}

      {:error, _} ->
        {:error, nil}
    end
  end

  @spec find_num_closest_exponentiation_of_two(integer()) :: integer()
  defp find_num_closest_exponentiation_of_two(0), do: 1
  defp find_num_closest_exponentiation_of_two(1), do: 1
  defp find_num_closest_exponentiation_of_two(2), do: 1

  defp find_num_closest_exponentiation_of_two(num) do
    if num > 4 do
      find_num_closest_exponentiation_of_two(num, 8)
    else
      2
    end
  end

  @spec find_num_closest_exponentiation_of_two(integer(), integer()) :: integer()
  defp find_num_closest_exponentiation_of_two(num, acc) do
    if num > acc do
      find_num_closest_exponentiation_of_two(num, acc * 2)
    else
      div(acc, 2)
    end
  end

  defp check_exponentiation_of_two(0, base), do: {true, base}
  defp check_exponentiation_of_two(1, base), do: {true, base}

  defp check_exponentiation_of_two(num, base) do
    case rem(num, 2) do
      0 ->
        # 偶数の場合は2で割り続け、1か0になるんだったらokとする処理が書いてあるこれ
        div(num, 2)
        |> check_exponentiation_of_two(base)

      _ ->
        {false, base}
    end
  end

  defp check_exponentiation_of_two(num) do
    if rem(num, 2) == 0 do
      num
      |> div(2)
      |> check_exponentiation_of_two(num)
    else
      {false, num}
    end
  end

  defp tournament_start_check({:ok, attrs}) do
    if Repo.exists?(from t in Tournament, where: t.id == ^attrs["tournament_id"] and t.is_started) do
      {:ok, attrs}
    else
      {:error, "tournament is not started"}
    end
  end

  defp tournament_start_check({:error, error}) do
    {:error, error}
  end

  @doc """
  Initialize rank of users.
  TODO: リファクタリング優先度高め 型が不安定
  """
  @spec initialize_rank(any(), integer(), integer()) :: any()
  def initialize_rank(data, number_of_entrant, tournament_id) do
    __MODULE__.initialize_rank(data, number_of_entrant, tournament_id, 1)
  end

  @spec initialize_rank(any(), integer(), integer(), integer()) :: any()
  def initialize_rank(user_id, number_of_entrant, tournament_id, count)
      when is_integer(user_id) do
    final =
      if number_of_entrant < count do
        number_of_entrant
      else
        count
      end

    user_id
    |> get_entrant_by_user_id_and_tournament_id(tournament_id)
    |> update_entrant(%{rank: final})
    |> elem(1)
  end

  def initialize_rank(match_list, number_of_entrant, tournament_id, count) do
    Enum.map(match_list, fn x ->
      initialize_rank(x, number_of_entrant, tournament_id, count * 2)
    end)
  end

  #  def initialize_rank(match_list, number_of_entrant, tournament_id, count \\ 1), do: nil

  @doc """
  Initialize rank of teams.
  """
  @spec initialize_team_rank(any(), integer()) :: any()
  def initialize_team_rank(match_list, number_of_entrant) do
    __MODULE__.initialize_team_rank(match_list, number_of_entrant, 1)
  end

  @spec initialize_team_rank(any(), integer(), integer()) :: any()
  def initialize_team_rank(team_id, number_of_entrant, count)
      when is_integer(team_id) do
    final = if number_of_entrant < count, do: number_of_entrant, else: count

    team_id
    |> get_team()
    |> update_team(%{rank: final})
    |> elem(1)
  end

  def initialize_team_rank(match_list, number_of_teams, count) do
    Enum.map(match_list, fn x ->
      initialize_team_rank(x, number_of_teams, count * 2)
    end)
  end

  @doc """
  Checks tournament state.
  """
  # @spec state!(integer(), integer()) :: String.t()
  # def state!(tournament_id, user_id) do
  #   keyname = Rules.adapt_keyname(user_id)

  #   tournament_id
  #   |> __MODULE__.get_tournament()
  #   |> Map.get(:rule)
  #   |> case do
  #     "basic" -> Basic.state!(keyname)
  #     "flipban" -> FlipBan.state!(keyname)
  #     _ -> raise "Invalid tournament rule"
  #   end
  # end
  @spec state!(integer(), integer()) :: String.t()
  def state!(tournament_id, user_id) do
    tournament_id
    |> __MODULE__.get_tournament()
    |> do_state!(user_id)
  end

  defp do_state!(nil, _), do: "IsFinished"
  defp do_state!(%Tournament{is_started: is_started}, _) when not is_started, do: "IsNotStarted"

  defp do_state!(tournament, user_id) do
    id = Progress.get_necessary_id(tournament.id, user_id)
    check_user_role!(tournament, id, user_id)
  end

  @spec check_user_role!(Tournament.t(), integer(), integer()) :: String.t()
  defp check_user_role!(tournament, id, user_id) do
    is_manager = tournament.master_id == user_id
    is_assistant = is_assistant?(tournament, user_id)
    is_not_entrant = is_not_entrant?(tournament, user_id)
    is_member = is_member?(tournament, user_id)

    cond do
      is_manager && is_not_entrant -> "IsManager"
      !is_manager && is_assistant && is_not_entrant -> "IsAssistant"
      is_member -> "IsMember"
      :else -> check_has_lost!(tournament, id)
    end
  end

  @spec is_assistant?(Tournament.t(), integer()) :: boolean()
  defp is_assistant?(tournament, user_id) do
    tournament.id
    |> __MODULE__.get_assistants()
    |> Enum.filter(fn assistant ->
      assistant.user_id == user_id
    end)
    |> length()
    |> Kernel.!=(0)
  end

  @spec is_not_entrant?(Tournament.t(), integer()) :: boolean()
  defp is_not_entrant?(tournament, user_id) do
    if tournament.is_team do
      tournament.id
      |> get_teams_by_tournament_id()
      |> Enum.map(fn team ->
        get_team_members_by_team_id(team.id)
      end)
      |> List.flatten()
      |> Enum.map(& &1.user_id)
      |> Enum.all?(fn team_member_user_id ->
        team_member_user_id != user_id
      end)
    else
      tournament.id
      |> get_entrants()
      |> Enum.map(& &1.user_id)
      |> Enum.all?(fn entrant_user_id ->
        entrant_user_id != user_id
      end)
    end
  end

  @spec is_member?(Tournament.t(), integer()) :: boolean()
  defp is_member?(tournament, user_id) do
    if tournament.is_team do
      tournament.id
      |> __MODULE__.get_team_by_tournament_id_and_user_id(user_id)
      ~> team
      |> is_nil()
      |> if do
        false
      else
        leader = __MODULE__.get_leader(team.id)
        leader.user_id != user_id
      end
    else
      false
    end
  end

  # HACK: is_aloneの分の処理も挟んでいる
  @spec check_has_lost!(Tournament.t(), integer()) :: String.t()
  defp check_has_lost!(tournament, id) do
    match_list = Progress.get_match_list(tournament.id)
    match = find_match(match_list, id)

    cond do
      match_list == [] -> "IsFinished"
      has_lost?(match_list, id) -> "IsLoser"
      is_alone?(match) -> "IsAlone"
      :else -> check_wait_state!(tournament, id, match)
    end
  end

  @spec check_wait_state!(Tournament.t(), integer(), any()) :: String.t()
  defp check_wait_state!(tournament, id, match) do
    opponent_pending_list = load_opponent_pending_list(tournament, match, id)
    pending_list = Progress.get_match_pending_list(id, tournament.id)

    cond do
      pending_list == [] && tournament.enabled_coin_toss ->
        "ShouldFlipCoin"

      pending_list == [] ->
        "IsInMatch"

      pending_list != [] && opponent_pending_list == [] ->
        [{_, state}] = pending_list
        state

      pending_list != [] && tournament.enabled_map ->
        check_map_ban_state(tournament, id)

      :else ->
        "IsPending"
    end
  end

  defp load_opponent_pending_list(tournament, match, id) do
    tournament.is_team
    |> if do
      get_opponent_team(match, id)
    else
      get_opponent_user(match, id)
    end
    |> case do
      {:ok, %User{} = user} -> Progress.get_match_pending_list(user.id, tournament.id)
      {:ok, %Team{} = team} -> Progress.get_match_pending_list(team.id, tournament.id)
      {:wait, nil} -> raise "invalid opponent: {:wait, nil}"
      {:error, error} -> raise "invalid #{error}"
    end
  end

  @spec check_map_ban_state(Tournament.t(), integer()) :: String.t()
  defp check_map_ban_state(tournament, id) do
    tournament
    |> Map.get(:is_team)
    |> if do
      tournament
      |> Map.get(:id)
      |> Progress.get_match_list()
      |> find_match(id)
      |> get_opponent_team(id)
    else
      tournament
      |> Map.get(:id)
      |> Progress.get_match_list()
      |> find_match(id)
      |> get_opponent_user(id)
    end
    ~> {:ok, opponent}

    is_head? = __MODULE__.is_head_of_coin?(tournament.id, id, opponent.id)

    tournament
    |> Map.get(:id)
    |> Progress.get_ban_order(id)
    |> case do
      0 when is_head? ->
        "ShouldBan"

      0 ->
        "ShouldObserveBan"

      1 when is_head? ->
        "ShouldObserveBan"

      1 ->
        "ShouldBan"

      2 when is_head? ->
        "ShouldChooseMap"

      2 ->
        "ShouldObserveBan"

      3 when is_head? ->
        "ShouldObserveA/D"

      3 ->
        "ShouldChooseA/D"

      4 ->
        "IsPending"
    end
  end

  @doc """
  Returns data for tournament brackets.
  """
  @spec data_for_brackets(match_list()) :: [any()]
  def data_for_brackets(match_list) do
    {:ok, brackets} = Tournamex.brackets(match_list)
    brackets
  end

  @doc """
  Returns data with fight result for tournament brackets.
  """
  @spec data_with_fight_result_for_brackets(match_list()) :: [any()]
  def data_with_fight_result_for_brackets(match_list) do
    {:ok, brackets} = Tournamex.brackets_with_fight_result(match_list)
    brackets
  end

  @doc """
  Construct data with game scores for brackets.
  """
  @spec data_with_scores_for_brackets(integer()) :: [any()]
  def data_with_scores_for_brackets(tournament_id) do
    match_list = Progress.get_match_list_with_fight_result_including_log(tournament_id)

    # add game_scores
    match_list
    |> List.flatten()
    |> Enum.map(fn bracket ->
      user_id = bracket["user_id"]

      tournament_id
      |> Progress.get_best_of_x_tournament_match_logs_by_winner(user_id)
      |> Enum.map(fn log ->
        log.winner_score
      end)
      ~> win_game_scores

      tournament_id
      |> Progress.get_best_of_x_tournament_match_logs_by_loser(user_id)
      |> Enum.map(fn log ->
        log.loser_score
      end)
      ~> lose_game_scores

      game_scores = win_game_scores ++ lose_game_scores

      Map.put(bracket, "game_scores", game_scores)
    end)
  end

  @doc """
  Construct data with game scores for brackets.
  """
  @spec data_with_scores_for_flexible_brackets(integer()) :: [any()]
  def data_with_scores_for_flexible_brackets(tournament_id) do
    tournament_id
    |> Progress.get_match_list_with_fight_result_including_log()
    |> Tournamex.brackets_with_fight_result()
    |> elem(1)
    ~> brackets

    brackets
    |> Enum.map(fn list ->
      inspect(list, charlists: false)

      Enum.map(list, fn bracket ->
        unless is_nil(bracket) do
          id = bracket["user_id"] || bracket["team_id"]

          tournament_id
          |> Progress.get_best_of_x_tournament_match_logs_by_winner(id)
          |> Enum.map(fn log ->
            log.winner_score
          end)
          ~> win_game_scores

          tournament_id
          |> Progress.get_best_of_x_tournament_match_logs_by_loser(id)
          |> Enum.map(fn log ->
            log.loser_score
          end)
          |> Enum.concat(win_game_scores)
          ~> game_scores

          Map.put(bracket, "game_scores", game_scores)
        end
      end)
    end)
    |> List.flatten()
  end

  @doc """
  Returns tournament records.
  """
  @spec get_all_tournament_records(integer()) :: [TournamentLog.t()]
  def get_all_tournament_records(user_id) do
    user_id = Tools.to_integer_as_needed(user_id)

    EntrantLog
    |> where([el], el.user_id == ^user_id and el.rank != 0)
    |> Repo.all()
    |> Enum.map(fn entrant_log ->
      TournamentLog
      |> where([tl], tl.tournament_id == ^entrant_log.tournament_id)
      |> Repo.one()
      ~> tlog

      Map.put(entrant_log, :tournament_log, tlog)
    end)
    |> Enum.filter(fn entrant_log -> entrant_log.tournament_log != nil end)
  end

  @doc """
  Scores data.
  """
  @spec store_score(integer(), integer(), integer(), integer(), integer(), integer()) :: boolean()
  def store_score(tournament_id, winner_id, loser_id, winner_score, loser_score, match_index) do
    Progress.create_best_of_x_tournament_match_log(%{
      tournament_id: tournament_id,
      winner_id: winner_id,
      loser_id: loser_id,
      winner_score: winner_score,
      loser_score: loser_score,
      match_index: match_index
    })

    match_list = Progress.get_match_list_with_fight_result(tournament_id)
    match_list = Tournamex.win_count_increment(match_list, winner_id)
    Progress.delete_match_list_with_fight_result(tournament_id)
    Progress.insert_match_list_with_fight_result(match_list, tournament_id)
  end

  @doc """
  Create a team.
  """
  @spec create_team(integer(), integer(), integer(), [integer()]) :: {:ok, Team.t()} | {:error, Ecto.Changeset.t()}
  def create_team(_, _, _, user_id_list) when not is_list(user_id_list), do: {:error, "user id list should be list"}
  def create_team(tournament_id, size, leader_id, user_id_list) do
    with {:ok, nil} <- validate_user_is_not_member(tournament_id, user_id_list),
         {:ok, team} <- do_create_team(tournament_id, size, leader_id),
         {:ok, _} <- create_team_leader(team.id, leader_id),
         {:ok, members} <- __MODULE__.create_team_members(team.id, user_id_list),
         {:ok, _} <- __MODULE__.create_team_invitations(members, leader_id) do
      {:ok, Map.put(team, :team_member, members)}
    else
      error -> error
    end
  end

  @spec validate_user_is_not_member(integer(), [integer()]) :: {:ok, nil} | {:error, String.t()}
  defp validate_user_is_not_member(tournament_id, user_id_list) do
    user_id_list
    |> Enum.all?(fn user_id ->
      Team
      |> join(:inner, [t], tm in TeamMember, on: t.id == tm.team_id)
      |> where([t, tm], t.tournament_id == ^tournament_id)
      |> where([t, tm], tm.user_id == ^user_id)
      |> where([t, tm], tm.is_invitation_confirmed)
      |> Repo.all()
      |> Kernel.==([])
    end)
    |> Tools.boolean_to_tuple()
  end

  @spec do_create_team(integer(), integer(), integer()) :: {:ok, Team.t()} | {:error, Ecto.Changeset.t()}
  defp do_create_team(tournament_id, size, leader_id) do
    leader = Accounts.get_user(leader_id)

    %Team{}
    |> Team.changeset(%{
      "tournament_id" => tournament_id,
      "size" => size,
      "name" => "#{leader.name}のチーム",
      "icon_path" => leader.icon_path
    })
    |> Repo.insert()
  end

  @spec create_team_leader(integer(), integer()) :: {:ok, TeamMember.t()} | {:error, Ecto.Changeset.t()}
  defp create_team_leader(team_id, leader_id) do
    %TeamMember{}
    |> TeamMember.changeset(%{
      "team_id" => team_id,
      "user_id" => leader_id,
      "is_leader" => true,
      "is_invitation_confirmed" => true
    })
    |> Repo.insert()
  end

  @spec create_team_members(integer(), [integer()]) :: {:ok, [TeamMember.t()]}
  def create_team_members(team_id, user_id_list) do
    # todo: トランザクションを使おう
    Enum.map(user_id_list, fn id ->
      %TeamMember{}
      |> TeamMember.changeset(%{"team_id" => team_id, "user_id" => id})
      |> Repo.insert()
      |> elem(1)
      |> Repo.preload(:user)
      ~> member

      user = Repo.preload(member.user, :auth)
      Map.put(member, :user, user)
    end)
    ~> result

    {:ok, result}
  end

  @spec create_team_invitations([TeamMember.t()], integer()) :: {:ok, any()} | {:error, any()} | {:error, Ecto.Multi.name(), any(), map()}
  def create_team_invitations(team_members, leader_id) do
    team_members
    |> Enum.reduce(Multi.new(), &insert_team_invitation_transaction(&1, leader_id, &2))
    |> Repo.transaction()
  end

  defp insert_team_invitation_transaction(team_member, leader_id, multi) do
    Multi.insert(multi, :"#{team_member.id}", fn _ ->
      TeamInvitation.changeset(%{
        "team_member_id" => team_member.id,
        "sender_id" => leader_id
      })
    end)
  end

  @doc """
  Get a team.
  """
  @spec get_team(integer()) :: Team.t() | nil
  def get_team(team_id) do
    Team
    |> where([t], t.id == ^team_id)
    |> Repo.one()
    |> Repo.preload(:team_member)
    ~> team
    |> is_nil()
    |> unless do
      team
      |> Map.get(:team_member)
      |> Repo.preload(:user)
      |> Enum.map(fn member ->
        user = Repo.preload(member.user, :auth)
        Map.put(member, :user, user)
      end)
      ~> team_members

      Map.put(team, :team_member, team_members)
    end
  end

  @doc """
  Get teams by tournament_id.
  """
  @spec get_teams_by_tournament_id(integer()) :: [Team.t()]
  def get_teams_by_tournament_id(tournament_id) do
    Team
    |> where([t], t.tournament_id == ^tournament_id)
    |> Repo.all()
  end

  @doc """
  Get team by tournament_id and user_id.
  """
  @spec get_team_by_tournament_id_and_user_id(integer(), integer()) :: Team.t() | nil
  def get_team_by_tournament_id_and_user_id(tournament_id, user_id) do
    Team
    |> join(:inner, [t], tm in TeamMember, on: t.id == tm.team_id)
    |> where([t, tm], t.tournament_id == ^tournament_id)
    |> where([t, tm], tm.user_id == ^user_id)
    |> Repo.one()
  end

  @doc """
  Get team members by team id.
  """
  @spec get_team_members_by_team_id(integer()) :: [TeamMember.t()]
  def get_team_members_by_team_id(team_id) do
    TeamMember
    |> where([tm], tm.team_id == ^team_id)
    |> Repo.all()
    |> Repo.preload(:user)
  end

  @doc """
  Get team member by team invitation id.
  """
  @spec get_team_by_invitation_id(integer()) :: Team.t() | nil
  def get_team_by_invitation_id(invitation_id) do
    Team
    |> join(:inner, [t], tm in TeamMember, on: t.id == tm.team_id)
    |> join(:inner, [t, tm], ti in TeamInvitation, on: tm.id == ti.team_member_id)
    |> where([t, tm, ti], ti.id == ^invitation_id)
    |> Repo.one()
  end

  @doc """
  Get leader of a team.
  """
  @spec get_leader(integer()) :: TeamMember.t() | nil
  def get_leader(team_id) do
    TeamMember
    |> where([tm], tm.team_id == ^team_id)
    |> where([tm], tm.is_leader)
    |> Repo.one()
    |> Repo.preload(:user)
  end

  @doc """
  Checks if the user is a leader
  """
  @spec is_leader?(integer(), integer()) :: boolean()
  def is_leader?(tournament_id, user_id) do
    tournament_id
    |> __MODULE__.get_tournament_including_logs()
    |> case do
      {:ok, %Tournament{} = tournament} -> tournament
      {:ok, %TournamentLog{} = tournament_log} -> tournament_log
      _ -> nil
    end
    |> do_is_leader?(user_id)
  end

  @spec do_is_leader?(Tournament.t() | TournamentLog.t() | Team.t() | TeamLog.t() | nil, integer()) :: boolean()
  defp do_is_leader?(nil, _), do: false

  defp do_is_leader?(%Tournament{is_team: false}, _), do: false
  defp do_is_leader?(%Tournament{id: id, is_team: true}, user_id) do
    id
    |> __MODULE__.get_team_by_tournament_id_and_user_id(user_id)
    |> do_is_leader?(user_id)
  end

  defp do_is_leader?(%TournamentLog{is_team: false}, _), do: false
  defp do_is_leader?(%TournamentLog{tournament_id: tournament_id, is_team: true}, user_id) do
    tournament_id
    |> Log.get_team_log_by_tournament_id_and_user_id(user_id)
    |> do_is_leader?(user_id)
  end

  defp do_is_leader?(%Team{id: id}, user_id) do
    leader = __MODULE__.get_leader(id)
    leader.user_id == user_id
  end

  defp do_is_leader?(%TeamLog{team_id: team_id}, user_id) do
    team_id
    |> Log.get_team_member_logs()
    |> Enum.filter(& &1.is_leader)
    |> Enum.all?(&(&1.user_id == user_id))
  end

  @doc """
  Get teams
  """
  @spec get_teammates(integer(), integer()) :: [Team.t()]
  def get_teammates(tournament_id, user_id) do
    Team
    |> join(:inner, [t], tm in TeamMember, on: t.id == tm.team_id)
    |> where([t, tm], t.tournament_id == ^tournament_id)
    |> preload([t, tm], :team_member)
    |> Repo.all()
    |> Enum.filter(fn team ->
      team.team_member
      |> Enum.any?(fn member ->
        member.user_id == user_id
      end)
    end)
    |> case do
      [] -> []

      teams ->
        teams
        |> hd()
        |> Map.get(:team_member)
        |> Repo.preload(:user)
        |> Enum.map(fn member ->
          user = Repo.preload(member.user, :auth)
          Map.put(member, :user, user)
        end)
    end
  end

  @doc """
  Get invitations for a user.
  """
  @spec get_team_invitations_by_user_id(integer()) :: [TeamInvitation.t()]
  def get_team_invitations_by_user_id(user_id) do
    TeamInvitation
    |> join(:inner, [ti], tm in TeamMember, on: ti.team_member_id == tm.id)
    |> where([ti, tm], tm.user_id == ^user_id)
    |> Repo.all()
  end

  @doc """
  Get confirmed teams of a tournament.
  This is similar to get_entrants.
  """
  @spec get_confirmed_teams(integer()) :: [Team.t()]
  def get_confirmed_teams(tournament_id) do
    Team
    |> join(:inner, [t], tm in TeamMember, on: t.id == tm.team_id)
    |> where([t, tm], t.tournament_id == ^tournament_id)
    |> where([t, tm], t.is_confirmed)
    |> preload([t, tm], :team_member)
    |> Repo.all()
    |> Enum.map(fn team ->
      team.team_member
      |> Repo.preload(:user)
      |> Enum.map(fn member ->
        user = Repo.preload(member.user, :auth)
        Map.put(member, :user, user)
      end)
      ~> team_members

      Map.put(team, :team_member, team_members)
    end)
    |> Enum.filter(fn members_in_team ->
      Enum.all?(members_in_team.team_member, & &1.is_invitation_confirmed)
    end)
    |> Enum.uniq_by(& &1.id)
  end

  @doc """
  Check if the user has requested participation as a team.
  """
  @spec has_requested_as_team?(integer(), integer()) :: boolean()
  def has_requested_as_team?(user_id, tournament_id) do
    Team
    |> join(:inner, [t], tm in TeamMember, on: t.id == tm.team_id)
    |> where([t, tm], t.tournament_id == ^tournament_id)
    |> preload([t, tm], :team_member)
    |> Repo.all()
    |> Enum.uniq_by(fn team_with_member_info ->
      team_with_member_info.id
    end)
    |> Enum.any?(fn team ->
      team
      |> Map.get(:team_member)
      |> Enum.any?(fn member ->
        member.user_id == user_id
      end)
    end)
  end

  @doc """
  Check if the user has confirmed as a team participant.
  """
  @spec has_confirmed_as_team?(integer(), integer()) :: boolean()
  def has_confirmed_as_team?(user_id, tournament_id) do
    tournament_id
    |> __MODULE__.get_confirmed_teams()
    |> Enum.any?(fn team ->
      team.id
      |> __MODULE__.get_team_members_by_team_id()
      |> Enum.any?(fn member ->
        member.user_id == user_id
      end)
    end)
  end

  @doc """
  Updates a team.
  """
  @spec update_team(Team.t() | integer(), map()) :: {:ok, Team.t()} | {:error, Ecto.Changeset.t()}
  def update_team(nil, _), do: {:error, "team is nil"}
  def update_team(%Team{} = team, attrs) do
    team
    |> Team.changeset(attrs)
    |> Repo.update()
  end

  def update_team(team_id, attrs) when is_integer(team_id) do
    team_id
    |> __MODULE__.get_team()
    |> __MODULE__.update_team(attrs)
  end

  @doc """
  Get invitations of user
  """
  @spec get_invitations(integer()) :: [TeamInvitation.t()]
  def get_invitations(user_id) do
    TeamInvitation
    |> join(:inner, [ti], tm in TeamMember, on: ti.team_member_id == tm.id)
    |> where([ti, tm], tm.user_id == ^user_id)
    |> Repo.all()
  end

  @doc """
  Get invitations by tournament id.
  """
  @spec get_invitations_by_tournament_id(integer()) :: [TeamInvitation.t()]
  def get_invitations_by_tournament_id(tournament_id) do
    TeamInvitation
    |> join(:inner, [ti], tm in TeamMember, on: ti.team_member_id == tm.id)
    |> join(:inner, [ti, tm], t in Team, on: t.id == tm.team_id)
    |> join(:inner, [ti, tm, t], tournament in Tournament, on: t.tournament_id == tournament.id)
    |> where([ti, tm, t, tournament], tournament.id == ^tournament_id)
    |> Repo.all()
  end

  @spec get_team_invitation(integer()) :: TeamInvitation.t() | nil
  def get_team_invitation(invitation_id) do
    TeamInvitation
    |> Repo.get(invitation_id)
    |> Repo.preload(:sender)
    |> Repo.preload(:team_member)
    |> Repo.preload(team_member: :user)
  end

  @spec team_invitation_decline(integer()) ::
          {:ok, TeamInvitation.t()} | {:error, Ecto.Changeset.t()}
  def team_invitation_decline(id) do
    id
    |> __MODULE__.get_team_invitation()
    ~> invitation
    |> Map.get(:team_member)
    |> Repo.delete()
    |> case do
      {:ok, %TeamMember{} = _member} ->
        create_team_invitation_result_notification(invitation, false)
        {:ok, invitation}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Create team invitation
  """
  @spec create_team_invitation(integer(), integer()) ::
          {:ok, TeamInvitation.t()} | {:error, Ecto.Changeset.t()}
  def create_team_invitation(team_member_id, sender_id) do
    %TeamInvitation{}
    |> TeamInvitation.changeset(%{
      "team_member_id" => team_member_id,
      "sender_id" => sender_id
    })
    |> Repo.insert()
    |> case do
      {:ok, invitation} ->
        invitation
        |> Repo.preload(:team_member)
        |> Repo.preload(:sender)
        |> create_invitation_notification()

        {:ok, invitation}

      {:error, error} ->
        {:error, error}
    end
  end

  defp create_invitation_notification(invitation) do
    %{
      "user_id" => invitation.team_member.user_id,
      "process_id" => "TEAM_INVITE",
      "icon_path" => invitation.sender.icon_path,
      "title" => "#{invitation.sender.name} からチーム招待されました",
      "body_text" => "",
      "data" =>
        Jason.encode!(%{
          invitation_id: invitation.id
        })
    }
    |> Notif.create_notification()
    |> case do
      {:ok, notification} ->
        push_invitation_notification(notification)

      {:error, error} ->
        {:error, error}
    end

    for device <- Accounts.get_devices_by_user_id(invitation.team_member.user_id) do
      %Maps.PushIos{
        user_id: invitation.team_member.user_id,
        device_token: device.token,
        process_id: "TEAM_INVITE",
        title: "",
        message: "#{invitation.sender.name} からチーム招待されました",
        params: %{"invitation_id" => invitation.id}
      }
      |> Milk.Notif.push_ios()
    end
  end

  defp push_invitation_notification(%Notification{} = _notification) do
    # TODO: push通知に関する処理を書く
  end

  @doc """
  Confirm invitation.
  """
  @spec confirm_team_invitation(integer()) :: {:ok, TeamMember.t()} | {:error, Ecto.Changeset.t()}
  def confirm_team_invitation(team_invitation_id) do
    TeamMember
    |> join(:inner, [tm], ti in TeamInvitation, on: tm.id == ti.team_member_id)
    |> where([tm, ti], ti.id == ^team_invitation_id)
    |> Repo.one()
    |> TeamMember.changeset(%{"is_invitation_confirmed" => true})
    |> Repo.update()
    |> case do
      {:ok, team_member} ->
        with %TeamInvitation{} = invitation <- get_team_invitation(team_invitation_id) do
          create_team_invitation_result_notification(invitation, true)
          verify_team_as_needed(team_member.team_id)
          {:ok, team_member}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  @spec create_team_invitation_result_notification(TeamInvitation.t(), boolean()) :: any()
  # TODO: 大会名などを含めたい
  def create_team_invitation_result_notification(invitation, result) do
    case result do
      true ->
        %{
          "user_id" => invitation.sender.id,
          "process_id" => "TEAM_INVITE_RESULT",
          "icon_path" => invitation.team_member.user.icon_path,
          "title" => "#{invitation.team_member.user.name} がチームに参加しました",
          "body_text" => "",
          "data" =>
            Jason.encode!(%{
              invitation_id: invitation.id
            })
        }
        |> Notif.create_notification()

        for device <- Accounts.get_devices_by_user_id(invitation.sender.id) do
          %Maps.PushIos{
            user_id: invitation.sender.id,
            device_token: device.token,
            process_id: "TEAM_INVITE_RESULT",
            title: "",
            message: "#{invitation.team_member.user.name} がチームに参加しました",
            params: %{"invitation_id" => invitation.id}
          }
          |> Milk.Notif.push_ios()
        end

      false ->
        %{
          "user_id" => invitation.sender.id,
          "process_id" => "TEAM_INVITE_RESULT",
          "icon_path" => invitation.team_member.user.icon_path,
          "title" => "#{invitation.team_member.user.name} がチームへの招待を辞退しました",
          "body_text" => "",
          "data" =>
            Jason.encode!(%{
              invitation_id: invitation.id
            })
        }
        |> Notif.create_notification()

        for device <- Accounts.get_devices_by_user_id(invitation.sender.id) do
          %Maps.PushIos{
            user_id: invitation.sender.id,
            device_token: device.token,
            process_id: "TEAM_INVITE_RESULT",
            title: "",
            message: "#{invitation.team_member.user.name} がチームへの招待を辞退しました",
            params: %{"invitation_id" => invitation.id}
          }
          |> Milk.Notif.push_ios()
        end
    end
  end

  defp verify_team_as_needed(team_id) do
    TeamMember
    |> where([tm], tm.team_id == ^team_id)
    |> where([tm], tm.is_invitation_confirmed)
    |> Repo.aggregate(:count)
    ~> confirmed_count

    team = Repo.get(Team, team_id)

    if confirmed_count >= team.size do
      Team
      |> where([t], t.id == ^team_id)
      |> Repo.one()
      |> Team.changeset(%{"is_confirmed" => true})
      |> Repo.update()
    else
      {:error, "short of confirmed count: #{confirmed_count}"}
    end
    |> case do
      {:ok, team} ->
        take_members_into_chat(team)
        invite_members_to_discord_as_needed(team)
        {:ok, team}

      {:error, error} ->
        {:error, error}
    end
  end

  defp take_members_into_chat(team) do
    TeamMember
    |> where([tm], tm.team_id == ^team.id)
    |> Repo.all()
    |> Enum.each(fn member ->
      member
      |> Map.get(:team_id)
      |> get_team()
      |> Map.get(:tournament_id)
      |> Chat.get_chat_rooms_by_tournament_id()
      |> Enum.each(fn chat_room ->
        Map.new()
        |> Map.put("user_id", member.user_id)
        |> Map.put("authority", 1)
        |> Map.put("chat_room_id", chat_room.id)
        |> Chat.create_chat_member()
      end)
    end)
  end

  defp invite_members_to_discord_as_needed(team) do
    team
    |> Map.get(:tournament_id)
    |> get_tournament()
    ~> tournament
    |> Map.get(:discord_server_id)
    ~> server_id
    |> is_nil()
    |> unless do
      url = Discord.create_invitation_link!(server_id)

      team
      |> Map.get(:id)
      |> get_team_members_by_team_id()
      |> Enum.each(fn member ->
        %{
          "user_id" => member.user_id,
          "process_id" => "DISCORD_SERVER_INVITATION",
          "icon_path" => tournament.thumbnail_path,
          "title" => "#{tournament.name}のDiscordサーバーへの招待を受け取りました",
          "body_text" => "",
          "data" =>
            Jason.encode!(%{
              url: url
            })
        }
        |> Notif.create_notification()
        |> case do
          {:ok, notification} ->
            push_invitation_notification(notification)

          {:error, error} ->
            {:error, error}
        end
      end)
    end
  end

  @doc """
  Delete a team
  """
  @spec delete_team(Team.t() | integer()) :: {:ok, Team.t()} | {:error, Ecto.Changeset.t()}
  def delete_team(nil), do: {:error, "team is nil"}
  def delete_team(%Team{} = team), do: Repo.delete(team)

  def delete_team(team_id) do
    team_id
    |> __MODULE__.get_team()
    |> __MODULE__.delete_team()
    |> case do
      {:ok, team} ->
        team = Repo.preload(team, :team_member)
        {:ok, team}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Delete a team and store it.
  """
  @spec delete_team_and_store(integer()) :: {:ok, Team.t()} | {:error, Ecto.Changeset.t()}
  def delete_team_and_store(team_id) do
    Team
    |> Repo.get(team_id)
    ~> team
    |> Map.from_struct()
    |> Map.put(:team_id, team_id)
    |> Tools.atom_map_to_string_map()
    |> Log.create_team_log()

    team
    |> Repo.delete()
    |> case do
      {:ok, team} ->
        team = Repo.preload(team, :team_member)
        {:ok, team}

      {:error, error} ->
        {:error, error}
    end
  end

  @spec get_push_notice_job(String.t(), integer()) :: Oban.Job.t() | nil
  def get_push_notice_job(args, tournament_id) do
    Oban.Job
    |> where([j], j.state in ~w(available scheduled))
    |> where([j], j.args[^args] == ^tournament_id)
    |> Repo.one()
  end

  @doc """
  Create custom detail of a tournament.
  """
  @spec create_custom_detail(map()) ::
          {:ok, TournamentCustomDetail.t()} | {:error, Ecto.Changeset.t()}
  def create_custom_detail(attrs \\ %{}) do
    %TournamentCustomDetail{}
    |> TournamentCustomDetail.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Get custom detail.
  """
  @spec get_custom_detail_by_tournament_id(integer()) :: TournamentCustomDetail.t() | nil
  def get_custom_detail_by_tournament_id(tournament_id) do
    TournamentCustomDetail
    |> where([t], t.tournament_id == ^tournament_id)
    |> Repo.one()
    |> Repo.preload(:tournament)
  end

  @doc """
  Update custom detail
  """
  @spec update_custom_detail(TournamentCustomDetail.t() | nil, map()) :: {:ok, TournamentCustomDetail.t()} | {:error, Ecto.Changeset.t()}
  def update_custom_detail(nil, _), do: {:error, "given detail is nil"}
  def update_custom_detail(detail, attrs) do
    detail
    |> TournamentCustomDetail.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Create map
  """
  @spec create_map(map()) :: {:ok, Milk.Tournaments.Map.t()} | {:error, Ecto.Changeset.t()}
  def create_map(attrs \\ %{}) do
    attrs
    |> Map.has_key?("icon_b64")
    |> if do
      b64 = attrs["icon_b64"]

      # XXX: inspectしないとb64が正常に読み込まれないことがある
      inspect(b64)
      img = Base.decode64!(b64)

      uuid = SecureRandom.uuid()
      path = "./static/image/options/#{uuid}.jpg"
      FileUtils.write(path, img)

      :milk
      |> Application.get_env(:environment)
      |> case do
        :prod ->
          "./static/image/options/#{uuid}.jpg"
          |> Milk.CloudStorage.Objects.upload()
          |> Map.get(:name)
          ~> name

          File.rm(path)
          name

        _ ->
          path
      end
      ~> name

      Map.put(attrs, "icon_path", name)
    else
      attrs
    end
    ~> attrs

    %Milk.Tournaments.Map{}
    |> Milk.Tournaments.Map.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Get a map.
  """
  @spec get_map(integer()) :: Milk.Tournaments.Map.t() | MapSelection.t()
  def get_map(map_id) do
    MapSelection
    |> where([ms], ms.map_id == ^map_id)
    |> Repo.one()
    |> Repo.preload(:map)
    ~> map_selection

    Milk.Tournaments.Map
    |> where([ms], ms.id == ^map_id)
    |> Repo.one()
    ~> map

    unless is_nil(map_selection) do
      map_selection
      |> Map.get(:map)
      |> Map.put(:state, map_selection.state)
    else
      Map.put(map, :state, "not_selected")
    end
  end

  @doc """
  Get maps by tournament id
  """
  @spec get_maps_by_tournament_id(integer()) :: [Milk.Tournaments.Map.t()]
  def get_maps_by_tournament_id(tournament_id) do
    Milk.Tournaments.Map
    |> where([ms], ms.tournament_id == ^tournament_id)
    |> Repo.all()
  end

  @doc """
  Create map selection.
  """
  @spec create_map_selection(map()) :: {:ok, MapSelection.t()} | {:error, Ecto.Changeset.t()}
  def create_map_selection(attrs \\ %{}) do
    %MapSelection{}
    |> MapSelection.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Get map selections.
  """
  @spec get_map_selections(integer(), integer(), integer()) :: [MapSelection.t()]
  def get_map_selections(_tournament_id, small_id, large_id) do
    MapSelection
    |> join(:inner, [ms], m in Milk.Tournaments.Map, on: ms.map_id == m.id)
    |> where([ms, m], ms.large_id == ^large_id)
    |> where([ms, m], ms.small_id == ^small_id)
    |> Repo.all()
    |> Repo.preload(:map)
  end

  @doc """
  Get selectable maps by user id and tournament id.
  """
  @spec get_selectable_maps_by_tournament_id_and_user_id(integer(), integer()) :: [
          Milk.Tournaments.Map.t() | MapSelection.t()
        ]
  def get_selectable_maps_by_tournament_id_and_user_id(tournament_id, user_id) do
    tournament_id
    |> get_tournament()
    ~> tournament

    tournament
    |> Map.get(:is_team)
    |> if do
      tournament_id
      |> get_team_by_tournament_id_and_user_id(user_id)
      |> Map.get(:id)
    else
      user_id
    end
    ~> my_id

    tournament
    |> Map.get(:is_team)
    |> if do
      tournament_id
      |> Progress.get_match_list()
      |> find_match(my_id)
      |> get_opponent_team(my_id)
    else
      tournament_id
      |> Progress.get_match_list()
      |> find_match(my_id)
      |> get_opponent_user(my_id)
    end
    |> elem(1)
    |> Map.get(:id)
    ~> opponent_id

    if opponent_id > my_id do
      {opponent_id, my_id}
    else
      {my_id, opponent_id}
    end
    ~> {large_id, small_id}

    tournament_id
    |> get_map_selections(small_id, large_id)
    |> Enum.map(fn map_selection ->
      map_selection
      |> Map.get(:map)
      |> Map.put(:state, map_selection.state)
    end)
    ~> map_selections

    tournament_id
    |> get_maps_by_tournament_id()
    |> Enum.map(fn map ->
      Map.put(map, :state, "not_selected")
    end)
    ~> maps

    map_selections
    |> Enum.concat(maps)
    |> Enum.uniq_by(fn map ->
      map.id
    end)
  end

  @doc """
  Get selected map by tournament id.
  """
  @spec get_selected_map(integer(), integer()) ::
          {:ok, Milk.Tournaments.Map.t()} | {:error, String.t()}
  def get_selected_map(tournament_id, id) do
    MapSelection
    |> join(:inner, [ms], m in Milk.Tournaments.Map, on: ms.map_id == m.id)
    |> where([ms, m], m.tournament_id == ^tournament_id)
    |> where([ms, m], ms.large_id == ^id or ms.small_id == ^id)
    |> Repo.all()
    |> Repo.preload(:map)
    |> Enum.filter(fn map ->
      map.state == "selected"
    end)
    |> Enum.map(fn map_selection ->
      map_selection
      |> Map.get(:map)
      |> Map.put(:state, map_selection.state)
    end)
    ~> maps
    |> length()
    |> case do
      1 -> {:ok, hd(maps)}
      0 -> {:error, "not selected any maps"}
      n -> {:error, "selected too many maps (length: #{n})"}
    end
  end

  @doc """
  Delete map selection.
  """
  @spec delete_map_selection(MapSelection.t()) ::
          {:ok, MapSelection.t()} | {:error, Ecto.Changeset.t()}
  def delete_map_selection(%MapSelection{} = map_selection) do
    Repo.delete(map_selection)
  end

  @doc """
  Delete map selections
  """
  @spec delete_map_selections(integer(), integer()) :: :ok
  def delete_map_selections(tournament_id, id) do
    MapSelection
    |> join(:inner, [ms], m in Milk.Tournaments.Map, on: ms.map_id == m.id)
    |> where([ms, m], ms.large_id == ^id or ms.small_id == ^id)
    |> where([ms, m], m.tournament_id == ^tournament_id)
    |> Repo.all()
    |> Enum.each(fn map_selection ->
      delete_map_selection(map_selection)
    end)
  end

  @doc """
  Update map.
  """
  @spec update_map(Milk.Tournaments.Map.t(), map()) ::
          {:ok, Milk.Tournaments.Map.t()} | {:error, Ecto.Changeset.t()}
  def update_map(%Milk.Tournaments.Map{} = map, attrs) do
    map
    |> Milk.Tournaments.Map.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Calculate given user(team) is head of a flipped coin.
  """
  @spec is_head_of_coin?(integer(), integer(), integer()) :: boolean()
  def is_head_of_coin?(tournament_id, id, opponent_id)
      when is_integer(tournament_id) and
             is_integer(id) and
             is_integer(opponent_id) do
    mine_str = to_string(tournament_id + id)
    opponent_str = to_string(tournament_id + opponent_id)

    :crypto.hash(:sha256, mine_str)
    |> Base.encode16()
    |> String.downcase()
    ~> mine

    :crypto.hash(:sha256, opponent_str)
    |> Base.encode16()
    |> String.downcase()
    ~> his

    mine > his
  end
end

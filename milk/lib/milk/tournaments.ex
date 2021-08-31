defmodule Milk.Tournaments do
  @moduledoc """
  The Tournaments context.
  """
  use Timex

  import Ecto.Query, warn: false
  import Common.Sperm

  alias Ecto.Multi
  alias Common.Tools

  alias Milk.{
    Accounts,
    Chat,
    Log,
    Notif,
    TournamentProgress,
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
    TournamentChatTopicLog,
    TournamentLog
  }

  alias Milk.Notif.Notification

  alias Milk.Tournaments.{
    Assistant,
    Entrant,
    Team,
    TeamInvitation,
    TeamMember,
    Tournament,
    TournamentChatTopic,
    TournamentCustomDetail
  }

  require Integer
  require Logger

  @typedoc """
  Tournament changeset structure.

  The types %Tournament{} and Tournaments are equivalent.
  """
  @type t :: %Tournament{}

  @doc """
  Returns the list of tournament for home screen.
  """
  def home_tournament(date_offset, offset, user_id \\ nil) do
    offset = Tools.to_integer_as_needed(offset)

    if user_id do
      user_id
      |> Relations.blocked_users()
      |> Enum.map(fn relation -> relation.blocked_user_id end)
    else
      []
    end
    ~> blocked_user_id_list

    Timex.now()
    |> Timex.add(Timex.Duration.from_days(1))
    |> Timex.to_datetime()
    ~> filter_date

    Tournament
    # |> where([t], t.deadline > ^filter_date and t.create_time < ^date_offset)
    |> where([t], not (t.master_id in ^blocked_user_id_list))
    |> order_by([t], asc: :event_date)
    |> offset(^offset)
    |> limit(5)
    |> Repo.all()
    |> Repo.preload(:entrant)
    |> Repo.preload(:team)
  end

  @doc """
  Returns the list of tournament which is filtered by "fav" for home screen.
  """
  def home_tournament_fav(user_id) do
    Relation
    |> where([r], r.follower_id == ^user_id)
    |> Repo.all()
    |> Enum.map(fn relation ->
      relation.followee_id
    end)
    ~> users

    Tournament
    |> where([t], t.master_id in ^users)
    |> date_filter()
    |> Repo.all()
    |> Repo.preload(:entrant)
    |> Repo.preload(:team)
  end

  @doc """
  Returns the list of tournament which is filtered by "plan" for home screen.
  """
  def home_tournament_plan(user_id) do
    Tournament
    |> where([t], t.master_id == ^user_id)
    |> date_filter()
    |> Repo.all()
    |> Repo.preload(:entrant)
    |> Repo.preload(:team)
  end

  @doc """
  Get searched tournaments as home.
  """
  def search(_user_id, text) do
    like = "%#{text}%"

    from(
      t in Tournament,
      where: like(t.name, ^like) or like(t.game_name, ^like)
    )
    |> date_filter()
    |> Repo.all()
  end

  defp date_filter(query) do
    query
    |> where([e], e.deadline > ^Timex.now())
    |> order_by([e], asc: :event_date)
  end

  @doc """
  Returns the list of tournament specified with a game id.
  """
  def get_tournament_by_game_id(game_id) do
    Repo.all(from t in Tournament, where: t.game_id == ^game_id)
  end

  @doc """
  Get a tournament by room id.
  """
  def get_tournament_by_room_id(chat_room_id) do
    TournamentChatTopic
    |> where([tct], tct.chat_room_id == ^chat_room_id)
    |> Repo.one()
    |> case do
      nil ->
        {:error, "the tournament was not found."}

      topic ->
        Tournament
        |> where([t], t.id == ^topic.tournament_id)
        |> Repo.one()
    end
  end

  @doc """
  Returns tournaments which are filtered by master id.
  """
  def get_tournaments_by_master_id(user_id) do
    Repo.all(from t in Tournament, where: t.master_id == ^user_id)
  end

  def get_tournament_logs_by_master_id(user_id) do
    Repo.all(from tl in TournamentLog, where: tl.master_id == ^user_id)

    TournamentLog
    |> where([tl], tl.master_id == ^user_id)
    |> order_by([tl], asc: :event_date)
    |> Repo.all()
    |> Enum.filter(fn tournament_log -> tournament_log.tournament_id != nil end)
    |> Enum.map(fn tournament_log ->
      entrants =
        EntrantLog
        |> where([el], el.tournament_id == ^tournament_log.tournament_id)
        |> Repo.all()

      Map.put(tournament_log, :entrants, entrants)
    end)
  end

  @doc """
  Returns tournaments which are filtered by user id of assistant.
  """
  def get_tournaments_by_assistant_id(user_id) do
    Assistant
    |> where([a], a.user_id == ^user_id)
    |> Repo.all()
    |> Enum.map(fn assistant ->
      get_tournament(assistant.tournament_id)
    end)
  end

  @doc """
  Returns ongoing tournaments of certain user.
  """
  def get_ongoing_tournaments_by_master_id(user_id) do
    Tournament
    |> where([t], t.event_date > ^Timex.now() and t.master_id == ^user_id)
    |> order_by([t], asc: :event_date)
    |> Repo.all()
    |> Repo.preload(:entrant)
  end

  @doc """
  Gets a single tournament.

  Raises `Ecto.NoResultsError` if the Tournament does not exist.
  """
  def get_tournament(id) do
    Tournament
    |> Repo.get(id)
    |> Repo.preload(:team)
    |> Repo.preload(:entrant)
    |> Repo.preload(:assistant)
    |> Repo.preload(:master)
    |> Repo.preload(:custom_detail)
    |> (fn tournament ->
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
        end).()
  end

  @doc """
  Gets single tournament by url.
  """
  def get_tournament_by_url(url) do
    Tournament
    |> where([t], t.url == ^url)
    |> Repo.one()
    |> Repo.preload(:custom_detail)
    |> Repo.preload(:team)
    |> Repo.preload(:entrant)
    |> Repo.preload(:assistant)
    |> Repo.preload(:master)
    |> (fn tournament ->
          entrants =
            tournament
            |> Map.get(:entrant)
            |> Enum.map(fn entrant ->
              user =
                entrant
                |> Repo.preload(:user)
                |> Map.get(:user)
                |> Repo.preload(:auth)

              Map.put(entrant, :user, user)
            end)

          Map.put(tournament, :entrant, entrants)
        end).()
  end

  @doc """
  Gets single tournament or tournament log.
  If tournament does not exist in the table, it checks log table.
  """
  def get_tournament_including_logs(id) do
    case get_tournament(id) do
      nil ->
        case Log.get_tournament_log_by_tournament_id(id) do
          nil -> {:error, nil}
          log -> {:ok, log}
        end

      tournament ->
        {:ok, tournament}
    end
  end

  @doc """
  Get tournaments which the user participating in.
  It includes team.
  """
  def get_participating_tournaments(user_id) do
    Tournament
    |> join(:inner, [t], e in Entrant, on: t.id == e.tournament_id)
    |> where([t, e], e.user_id == ^user_id)
    |> Repo.all()
    ~> entrants

    Tournament
    |> join(:inner, [t], te in Team, on: t.id == te.tournament_id)
    |> join(:inner, [t, te], tm in TeamMember, on: te.id == tm.team_id)
    |> where([t, te, tm], tm.user_id == ^user_id)
    |> where([t, te, tm], te.is_confirmed)
    |> Repo.all()
    |> Enum.concat(entrants)
    |> Enum.uniq()
  end

  def get_participating_tournaments(user_id, offset) do
    offset = Tools.to_integer_as_needed(offset)

    Entrant
    |> where([e], e.user_id == ^user_id)
    |> order_by([e], asc: :tournament_id)
    |> offset(^offset)
    |> limit(5)
    |> Repo.all()
    |> Enum.map(fn entrant ->
      get_tournament(entrant.tournament_id)
    end)
  end

  @doc """
  Get pending tournaments.
  Pending tournament means like "our team invitation for the tournament is still in progress "
  """
  def get_pending_tournaments(user_id) do
    Tournament
    |> join(:inner, [t], te in Team, on: t.id == te.tournament_id)
    |> join(:inner, [t, te], tm in TeamMember, on: te.id == tm.team_id)
    |> where([t, te, tm], tm.user_id == ^user_id)
    |> where([t, te, tm], not te.is_confirmed)
    |> Repo.all()
  end

  @doc """
  Get a list of master users' information of a tournament
  """
  def get_masters(tournament_id) do
    tournament = get_tournament(tournament_id)

    User
    |> where([u], u.id == ^tournament.master_id)
    |> Repo.all()
  end

  @doc """

  """
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
  Creates a tournament.

  ## Examples

      iex> create_tournament(%{field: value})
      {:ok, %Tournament{}}

      iex> create_tournament(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tournament(%{"master_id" => master_id} = params, thumbnail_path \\ "") do
    id = Tools.to_integer_as_needed(master_id)

    Repo.exists?(from u in User, where: u.id == ^id)
    |> if do
      create(params, thumbnail_path)
    else
      {:error, "Undefined User"}
    end
    |> case do
      {:ok, tournament} ->
        set_details(tournament, params)
        {:ok, tournament}

      {:error, error} ->
        {:error, error}
    end
  end

  defp create_topic(tournament, topic, tab_index, authority \\ 0) do
    {:ok, chat_room} =
      %{
        name: tournament.name <> "-" <> topic,
        member_count: tournament.count,
        authority: authority
      }
      |> Chat.create_chat_room()

    # メンバー追加
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
  """
  # TODO: エラーハンドリング
  def update_topic(tournament, current_tabs, new_tabs) do
    currentIds =
      Enum.map(current_tabs, fn tab ->
        tab.chat_room_id
      end)

    newIds =
      Enum.map(new_tabs, fn tab ->
        tab["chat_room_id"]
      end)

    removedTabIds = currentIds -- newIds

    Enum.each(removedTabIds, fn id ->
      ChatRoom
      |> where([c], c.id == ^id)
      |> Repo.delete_all()
    end)

    Enum.each(new_tabs, fn tab ->
      if tab["chat_room_id"] do
        topic =
          Repo.one(from c in TournamentChatTopic, where: c.chat_room_id == ^tab["chat_room_id"])

        update_tournament_chat_topic(topic, %{
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

  defp join_topics(tournament_id, master_id) do
    tournament_id
    |> Chat.get_chat_rooms_by_tournament_id()
    |> Enum.each(fn chat_room ->
      %{
        "user_id" => master_id,
        "authority" => 1,
        "chat_room_id" => chat_room.id
      }
      |> Chat.create_chat_member()
    end)
  end

  defp create(attrs, thumbnail_path) do
    master_id = Tools.to_integer_as_needed(attrs["master_id"])
    platform_id = Tools.to_integer_as_needed(attrs["platform"])

    attrs
    |> Map.has_key?("url")
    |> if do
      unless attrs["url"] == "" || is_nil(attrs["url"]) do
        attrs
        |> Map.get("url")
        |> String.split("/")
        |> Enum.reverse()
        |> hd()
        ~> token

        Map.put(attrs, "url_token", token)
      else
        attrs
      end
    else
      attrs
    end
    ~> attrs

    Multi.new()
    |> Multi.insert(
      :tournament,
      %Tournament{
        master_id: master_id,
        game_id: attrs["game_id"],
        thumbnail_path: thumbnail_path,
        platform_id: platform_id
      }
      |> Tournament.create_changeset(attrs)
    )
    |> Multi.insert(:group_topic, fn %{tournament: tournament} ->
      create_topic(tournament, "Group", 0)
    end)
    |> Multi.insert(:notification_topic, fn %{tournament: tournament} ->
      create_topic(tournament, "Notification", 1, 1)
    end)
    |> Multi.insert(:q_and_a_topic, fn %{tournament: tournament} ->
      create_topic(tournament, "Q&A", 2)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, tournament} ->
        join_topics(tournament.tournament.id, master_id)
        {:ok, tournament.tournament}

      {:error, error} ->
        {:error, error.errors}

      _ ->
        {:error, nil}
    end
  end

  defp set_details(tournament, params) do
    params
    |> Map.put("tournament_id", tournament.id)
    |> create_custom_detail()
  end

  @doc """
  Verify password.
  """
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
  def update_tournament(%Tournament{} = tournament, attrs) do
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

  def match_list_length(matchlist, n \\ 0) do
    Enum.reduce(matchlist, n, fn x, acc ->
      case x do
        x when is_list(x) -> acc + match_list_length(x, n)
        _ -> acc + 1
      end
    end)
  end

  defp update_details(tournament, params) do
    params
    |> Map.put(:tournament_id, tournament.id)
    |> Tools.atom_map_to_string_map()
    ~> params

    tournament
    |> Map.get(:id)
    |> get_custom_detail_by_tournament_id()
    |> update_custom_detail(params)
  end

  @doc """
  Deletes a tournament.

  ## Examples

      iex> delete_tournament(tournament)
      {:ok, %Tournament{}}

      iex> delete_tournament(tournament)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tournament(%Tournament{} = tournament) do
    delete_tournament(tournament.id)
  end

  def delete_tournament(tournament) when is_map(tournament) do
    delete_tournament(tournament["id"])
  end

  def delete_tournament(id) do
    tournament =
      Repo.one(
        from t in Tournament,
          left_join: a in assoc(t, :assistant),
          left_join: e in assoc(t, :entrant),
          where: t.id == ^id,
          preload: [assistant: a, entrant: e]
      )

    entrant =
      Enum.map(tournament.entrant, fn x ->
        %{
          rank: x.rank,
          user_id: x.user_id,
          tournament_id: x.tournament_id,
          update_time: x.update_time,
          create_time: x.create_time
        }
      end)

    if entrant, do: Repo.insert_all(EntrantLog, entrant)

    assistant =
      Enum.map(tournament.assistant, fn x ->
        %{
          user_id: x.user_id,
          tournament_id: x.tournament_id,
          update_time: x.update_time,
          create_time: x.create_time
        }
      end)

    if assistant, do: Repo.insert_all(AssistantLog, assistant)

    # TournamentLog.changeset(%TournamentLog{}, Map.from_struct(tournament))
    # |> Repo.insert()

    Repo.delete(tournament)
  end

  @doc """
  Returns the list of entrant.

  ## Examples

      iex> list_entrant()
      [%Entrant{}, ...]

  """
  def list_entrant() do
    Repo.all(Entrant)
  end

  @doc """
  Gets a single entrant.

  Raises `Ecto.NoResultsError` if the Entrant does not exist.

  ## Examples

      iex> get_entrant!(123)
      %Entrant{}

      iex> get_entrant!(456)
      ** (Ecto.NoResultsError)

  """
  def get_entrant!(id), do: Repo.get!(Entrant, id)
  def get_entrant(id), do: Repo.get(Entrant, id)

  defp get_entrant_by_user_id_and_tournament_id(user_id, tournament_id) do
    Repo.one(
      from e in Entrant, where: ^tournament_id == e.tournament_id and ^user_id == e.user_id
    )
  end

  @doc """
  Get entrants of a tournament.
  """
  def get_entrants(tournament_id) do
    Entrant
    |> where([e], e.tournament_id == ^tournament_id)
    |> Repo.all()
  end

  @doc """
  Get a single entrant or log.
  """
  def get_entrant_including_logs(id) do
    case get_entrant(id) do
      nil -> Log.get_entrant_log_by_entrant_id(id)
      entrant -> entrant
    end
  end

  def get_entrant_including_logs(tournament_id, user_id) do
    case get_entrant_by_user_id_and_tournament_id(user_id, tournament_id) do
      nil -> Log.get_entrant_log_by_user_id_and_tournament_id(user_id, tournament_id)
      entrant -> entrant
    end
  end

  @doc """
  Creates a entrant.

  ## Examples

      iex> create_entrant(%{field: value})
      {:ok, %Entrant{}}

      iex> create_entrant(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_entrant(attrs \\ %{}) do
    attrs
    |> user_exists?()
    |> tournament_exists?()
    |> is_not_team?()
    |> already_participant?()
    |> insert()
    |> case do
      {:ok, entrant} -> join_tournament_chat_room_as_needed(entrant, attrs)
      {:error, _, error, _data} when is_bitstring(error) -> {:error, error}
      {:error, _, error, _data} -> {:multierror, error.errors}
      {:error, error} -> {:error, error}
      _ -> {:error, nil}
    end
  end

  defp user_exists?(attrs) do
    with false <- is_nil(attrs["user_id"]),
         true <- Repo.exists?(from u in User, where: u.id == ^attrs["user_id"]) do
      {:ok, attrs}
    else
      _ -> {:error, "undefined user"}
    end
  end

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

  defp is_not_team?({:ok, attrs}) do
    unless attrs["tournament"].is_team do
      {:ok, attrs}
    else
      {:error, "requires team"}
    end
  end

  defp is_not_team?({:error, error}) do
    {:error, error}
  end

  defp already_participant?({:ok, attrs}) do
    unless Repo.exists?(
             from e in Entrant,
               where:
                 e.tournament_id == ^attrs["tournament_id"] and e.user_id == ^attrs["user_id"]
           ) do
      {:ok, attrs}
    else
      {:error, "already joined"}
    end
  end

  defp already_participant?({:error, error}) do
    {:error, error}
  end

  defp insert({:ok, attrs}) do
    user_id =
      if is_binary(attrs["user_id"]) do
        String.to_integer(attrs["user_id"])
      else
        attrs["user_id"]
      end

    tournament_id =
      if is_binary(attrs["tournament_id"]) do
        String.to_integer(attrs["tournament_id"])
      else
        attrs["tournament_id"]
      end

    Multi.new()
    |> Multi.run(:tournament, fn repo, _ ->
      case repo.one(from t in Tournament, where: t.id == ^tournament_id and t.capacity > t.count) do
        %Tournament{} = t -> {:ok, t}
        nil -> {:error, "capacity over"}
        _ -> {:error, ""}
      end
    end)
    |> Multi.insert(:entrant, fn _ ->
      %Entrant{user_id: user_id, tournament_id: tournament_id}
      |> Entrant.changeset(attrs)
    end)
    |> Multi.update(:update, fn %{tournament: tournament} ->
      Tournament.changeset(tournament, %{count: tournament.count + 1})
    end)
    |> Repo.transaction()
  end

  defp insert({:error, error}) do
    {:error, error}
  end

  defp join_tournament_chat_room_as_needed(entrant, attrs) do
    tournament = get_tournament(attrs["tournament_id"])

    if tournament.master_id == entrant.entrant.user_id do
      {:ok, entrant.entrant}
    else
      join_tournament_chat_room(entrant, attrs)
    end
  end

  # TODO: リファクタリングできそう
  defp join_tournament_chat_room(entrant, attrs) do
    user_id = Tools.to_integer_as_needed(attrs["user_id"])

    result =
      Chat.get_chat_rooms_by_tournament_id(entrant.tournament.id)
      |> Enum.reduce({:ok, nil}, fn chat_room, _acc ->
        join_params = %{
          "user_id" => user_id,
          "chat_room_id" => chat_room.id,
          "authority" => 0
        }

        with {:ok, chat_member} <- Chat.create_chat_member(join_params) do
          {:ok, chat_member}
        else
          {:error, reason} ->
            {:error, reason}

          _ ->
            {:error, nil}
        end
      end)

    with {:ok, _chat_member} <- result do
      {:ok, entrant.entrant}
    else
      {:error, reason} -> {:error, reason}
      _ -> {:error, nil}
    end
  end

  @doc """
  Updates a entrant.

  ## Examples

      iex> update_entrant(entrant, %{field: new_value})
      {:ok, %Entrant{}}

      iex> update_entrant(entrant, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_entrant(%Entrant{} = entrant, attrs) do
    entrant
    |> Entrant.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, chat_member} ->
        {:ok, chat_member}

      {:error, error} ->
        {:error, error.errors}

      _ ->
        {:error, nil}
    end
  end

  @doc """
  Deletes a entrant.

  ## Examples

      iex> delete_entrant(entrant)
      {:ok, %Entrant{}}

      iex> delete_entrant(entrant)
      {:error, %Ecto.Changeset{}}
  """
  def delete_entrant(tournament_id, user_id) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    user_id = Tools.to_integer_as_needed(user_id)

    unless Repo.exists?(
             from e in Entrant, where: e.tournament_id == ^tournament_id and e.user_id == ^user_id
           ) do
      {:error, "entrant not found"}
    else
      entrant =
        Entrant
        |> where([e], e.tournament_id == ^tournament_id and e.user_id == ^user_id)
        |> Repo.one()

      delete_entrant(entrant)

      get_tabs_by_tournament_id(tournament_id)
      |> Enum.each(fn x ->
        x.chat_room_id
        |> Chat.delete_chat_member(user_id)
      end)

      {:ok, entrant}
    end
  end

  def delete_entrant(%Entrant{} = entrant) do
    map =
      entrant
      |> Map.from_struct()
      |> Map.put(:entrant_id, entrant.id)

    %EntrantLog{}
    |> EntrantLog.changeset(map)
    |> Repo.insert()

    tournament = Repo.get(Tournament, entrant.tournament_id)

    Tournament.changeset(tournament, %{count: tournament.count - 1})
    |> Repo.update()

    Repo.delete(entrant)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking entrant changes.

  ## Examples

      iex> change_entrant(entrant)
      %Ecto.Changeset{data: %Entrant{}}

  """
  def change_entrant(%Entrant{} = entrant, attrs \\ %{}) do
    Entrant.changeset(entrant, attrs)
  end

  @doc """
  Get a rank of a user.
  """
  def get_rank(tournament_id, user_id) do
    with entrant <- get_entrant_including_logs(tournament_id, user_id),
         false <- is_nil(entrant) do
      Map.get(entrant, :rank)
    else
      true -> {:error, "entrant is not found"}
    end
  end

  @doc """
  Delete loser.
  TODO: エラーハンドリング
  loser_listは一人用
  """
  def delete_loser_process(tournament_id, loser_list) when is_list(loser_list) do
    match_list = TournamentProgress.get_match_list(tournament_id)

    match_list
    |> find_match(hd(loser_list))
    |> Enum.each(fn user_id ->
      if is_integer(user_id) do
        TournamentProgress.delete_match_pending_list(user_id, tournament_id)
        TournamentProgress.delete_fight_result(user_id, tournament_id)
      end
    end)

    renew_match_list(tournament_id, match_list, loser_list)
    updated_match_list = TournamentProgress.get_match_list(tournament_id)
    renew_match_list_with_fight_result(tournament_id, loser_list)
    # unless is_integer(updated_match_list), do: trim_match_list_as_needed(tournament_id)

    updated_match_list
  end

  defp renew_match_list_with_fight_result(tournament_id, [loser]) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    TournamentProgress.renew_match_list_with_fight_result(loser, tournament_id)
  end

  defp renew_match_list(tournament_id, match_list, loser_list) do
    unless match_list == [] do
      promote_winners_by_loser!(tournament_id, match_list, loser_list)
    end

    renew(loser_list, tournament_id)
  end

  defp renew(loser_list, tournament_id) do
    loser_list
    |> TournamentProgress.renew_match_list(tournament_id)
    |> unless do
      Process.sleep(100)
      renew(loser_list, tournament_id)
    end
  end

  @doc """
  Delete a loser in a matchlist
  """
  def delete_loser(match_list, loser) do
    Tournamex.delete_loser(match_list, loser)
  end

  def promote_winners_by_loser!(tournament_id, match_list, losers) when is_list(losers) do
    Enum.map(losers, fn loser ->
      match_list
      |> find_match(loser)
      |> case do
        [] ->
          {:error, nil}

        match ->
          tournament_id
          |> get_tournament()
          ~> tournament
          |> Map.get(:is_team)
          |> if do
            match
            |> get_opponent_team(loser)
            |> Tuple.append(tournament)
          else
            match
            |> get_opponent(loser)
            |> Tuple.append(tournament)
          end
      end
      |> case do
        {:ok, opponent, tournament} ->
          if tournament.is_team do
            Map.new()
            |> Map.put("tournament_id", tournament_id)
            |> Map.put("team_id", opponent["id"])
            |> promote_rank()
          else
            Map.new()
            |> Map.put("tournament_id", tournament_id)
            |> Map.put("user_id", opponent["id"])
            |> promote_rank()
          end

        {:wait, nil, _tournament} ->
          {:wait, nil}

        {:error, nil, _tournament} ->
          {:error, nil}
      end
    end)
  end

  def promote_winners_by_loser!(tournament_id, match_list, loser) do
    match_list
    |> find_match(loser)
    ~> match
    |> Kernel.==([])
    |> unless do
      match
      |> get_opponent(loser)
      |> case do
        {:ok, opponent} ->
          promote_rank(%{"tournament_id" => tournament_id, "user_id" => opponent["id"]})

        {:wait, nil} ->
          raise RuntimeError, "Expected {:ok, opponent} (got: {:wait, nil})"

        _ ->
          raise RuntimeError, "Unexpected Output"
      end
    end
  end

  @doc """
  Finds a 1v1 match of given id and match list.
  """
  def find_match(v, _) when is_integer(v), do: []

  def find_match(list, id, result \\ []) when is_list(list) do
    Enum.reduce(list, result, fn x, acc ->
      y = pick_user_id_as_needed(x)

      case y do
        y when is_list(y) -> find_match(y, id, acc)
        y when is_integer(y) and y == id -> acc ++ list
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
  Get an opponent of tournament match.
  """
  def get_opponent(match, user_id) do
    if Enum.member?(match, user_id) and length(match) == 2 do
      match
      |> Enum.filter(&(&1 != user_id))
      |> hd()
      ~> the_other
      |> is_integer()
      |> if do
        the_other
        |> Accounts.get_user()
        |> Map.from_struct()
        |> Tools.atom_map_to_string_map()
        ~> user
        |> Map.get("auth")
        |> Map.from_struct()
        |> Tools.atom_map_to_string_map()
        ~> auth

        opponent = Map.put(user, "auth", auth)

        {:ok, opponent}
      else
        {:wait, nil}
      end
    else
      {:error, "opponent does not exist"}
    end
  end

  @doc """
  Get opponent team.
  """
  def get_opponent_team(match, team_id) do
    if Enum.member?(match, team_id) and length(match) == 2 do
      match
      |> Enum.filter(&(&1 != team_id))
      |> hd()
      ~> the_other
      |> is_integer()
      |> if do
        the_other
        |> get_team()
        |> Map.from_struct()
        |> Tools.atom_map_to_string_map()
        ~> opponent

        {:ok, opponent}
      else
        {:wait, nil}
      end
    else
      {:error, "opponent team does not exist"}
    end
  end

  @doc """
  Checks whether the user have to wait.
  """
  def is_alone?(match) do
    Enum.filter(match, &is_list(&1)) != []
  end

  @doc """
  Checks whether the user has already lost.
  """
  def has_lost?(v, _) when is_integer(v), do: false

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
  FIXME: 引数の順序がfinishと逆
  FIXME: リファクタリング
  """
  def start(master_id, tournament_id) do
    master_id
    |> nil_check?(tournament_id)
    |> check_entrant_number(tournament_id)
    |> fetch_tournament(master_id, tournament_id)
    |> start()
  end

  defp nil_check?(master_id, tournament_id) do
    if !is_nil(master_id) and !is_nil(tournament_id) do
      {:ok, nil}
    else
      {:error, "master_id or tournament_id is nil"}
    end
  end

  defp check_entrant_number(check, tournament_id) do
    case check do
      {:ok, _} ->
        Entrant
        |> where([e], e.tournament_id == ^tournament_id)
        |> Repo.aggregate(:count)
        |> Kernel.>(1)
        |> if do
          {:ok, nil}
        else
          delete_tournament(tournament_id)
          {:error, "short of participants"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_tournament(check, master_id, tournament_id) do
    case check do
      {:ok, nil} ->
        Tournament
        |> where([t], t.master_id == ^master_id and t.id == ^tournament_id)
        |> Repo.one()
        ~> tournament
        |> is_nil()
        |> unless do
          {:ok, tournament}
        else
          {:error, "cannot find tournament"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp start(check) do
    case check do
      {:ok, tournament} ->
        unless tournament.is_started do
          tournament
          |> Tournament.changeset(%{is_started: true})
          |> Repo.update()
        else
          {:error, "tournament is already started"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Start a team tournament.
  """
  def start_team_tournament(tournament_id, master_id) do
    master_id
    |> nil_check?(tournament_id)
    |> is_team_num_enough?(tournament_id)
    |> fetch_tournament(master_id, tournament_id)
    |> start()
  end

  defp is_team_num_enough?(check, tournament_id) do
    case check do
      {:ok, _} ->
        tournament_id
        |> get_confirmed_teams()
        |> length()
        |> Kernel.>(1)
        |> if do
          {:ok, nil}
        else
          {:error, "short of teams"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Finish a tournament.
  トーナメントを終了させ、終了したトーナメントをログの方に移行して削除する
  """
  def finish(tournament_id, winner_user_id) do
    tournament_id
    |> get_tournament()
    |> Map.get(:is_team)
    |> if do
      finish_teams(tournament_id)
    else
      finish_entrants(tournament_id)
    end
    |> case do
      :ok ->
        finish_topics(tournament_id)
        finish_tournament(tournament_id, winner_user_id)

      :error ->
        false

      _ ->
        false
    end
  end

  defp finish_teams(tournament_id) do
    tournament_id
    |> get_teams_by_tournament_id()
    |> Enum.each(fn team ->
      Log.create_team_log(team.id)
      delete_team(team.id)
    end)
  end

  defp finish_entrants(tournament_id) do
    tournament_id
    |> get_entrants()
    |> Enum.each(fn entrant ->
      delete_entrant(entrant)
    end)
  end

  defp finish_tournament(tournament_id, winner_user_id) do
    tournament_id
    |> get_tournament()
    |> delete_tournament()
    ~> {:ok, tournament}

    tournament
    |> Map.from_struct()
    |> Map.put(:tournament_id, tournament.id)
    |> Map.put(:winner_id, winner_user_id)
    |> Tools.atom_map_to_string_map()
    |> Log.create_tournament_log()
    |> case do
      {:ok, _tournament_log} -> true
      {:error, _} -> false
    end
  end

  defp finish_topics(tournament_id) do
    TournamentChatTopic
    |> where([t], t.tournament_id == ^tournament_id)
    |> Repo.all()
    |> Enum.map(fn topic ->
      topic
      |> atom_topic_map_to_string_map()
      |> Log.create_tournament_chat_topic_log()
    end)
  end

  defp atom_tournament_map_to_string_map(%Tournament{} = tournament, winner_id) do
    %{
      "master_id" => tournament.master_id,
      "tournament_id" => tournament.id,
      "name" => tournament.name,
      "type" => tournament.type,
      "deadline" => tournament.deadline,
      "url" => tournament.url,
      "description" => tournament.description,
      "event_date" => tournament.event_date,
      "game_id" => tournament.game_id,
      "game_name" => tournament.game_name,
      "winner_id" => winner_id,
      "capacity" => tournament.capacity,
      "thumbnail_path" => tournament.thumbnail_path,
      "entrant" => tournament.entrant
    }
  end

  defp atom_topic_map_to_string_map(%TournamentChatTopic{} = topic) do
    %{
      "tournament_id" => topic.tournament_id,
      "topic_name" => topic.topic_name,
      "chat_room_id" => topic.chat_room_id,
      "tab_index" => topic.tab_index
    }
  end

  @doc """
  Get lost a player.
  """
  def get_lost(match_list, loser) do
    Tournamex.renew_match_list_with_loser(match_list, loser)
  end

  @doc """
  Generate a matchlist.
  """
  def generate_matchlist(list) do
    Tournamex.generate_matchlist(list)
  end

  @doc """
  Initialize fight result of match list.
  """
  def initialize_match_list_with_fight_result(match_list) do
    Tournamex.initialize_match_list_with_fight_result(match_list)
  end

  @doc """
  Initialize fight result of match list of teams.
  """
  def initialize_match_list_of_team_with_fight_result(match_list) do
    Tournamex.initialize_match_list_of_team_with_fight_result(match_list)
  end

  @doc """
  Put value on brackets.
  """
  def put_value_on_brackets(match_list, key, value) do
    Tournamex.put_value_on_brackets(match_list, key, value)
  end

  @doc """
  Gets a single assistant.

  Raises `Ecto.NoResultsError` if the Assistant does not exist.

  ## Examples

      iex> get_assistant!(123)
      %Assistant{}

      iex> get_assistant!(456)
      ** (Ecto.NoResultsError)

  """
  def get_assistant!(id), do: Repo.get!(Assistant, id)

  def get_assistant(id), do: Repo.get(Assistant, id)

  def get_assistants(tournament_id) do
    Assistant
    |> where([a], a.tournament_id == ^tournament_id)
    |> Repo.all()
  end

  def get_assistants_by_user_id(user_id) do
    Assistant
    |> where([a], a.user_id == ^user_id)
    |> Repo.all()
  end

  @doc """
  Get user information of an assistant.
  """
  def get_user_info_of_assistant(%Assistant{} = assistant) do
    User
    |> where([u], u.id == ^assistant.user_id)
    |> Repo.one()
  end

  @doc """
  Get fighting users.
  """
  def get_fighting_users(tournament_id) do
    tournament_id
    |> get_tournament()
    |> Map.get(:is_team)
    |> if do
      tournament_id
      |> get_confirmed_teams()
      |> Enum.filter(fn team ->
        team.id
        |> TournamentProgress.get_match_pending_list(tournament_id)
        |> Kernel.!=([])
      end)
    else
      tournament_id
      |> get_entrants()
      |> Enum.filter(fn entrant ->
        TournamentProgress.get_match_pending_list(entrant.user_id, tournament_id) != []
      end)
      |> Enum.map(fn entrant ->
        Accounts.get_user(entrant.user_id)
      end)
    end
  end

  @doc """
  Get users waiting for fighting ones.
  FIXME: usersと書いてあるがチームを扱う場合もある
  """
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
        |> TournamentProgress.get_match_list()
        |> List.flatten()
        ~> flatten_match_list

        team.id in flatten_match_list and !Enum.member?(fighting_users, team)
      end)
    else
      fighting_users = get_fighting_users(tournament_id)

      tournament_id
      |> get_entrants()
      |> Enum.filter(fn entrant ->
        match_list = TournamentProgress.get_match_list(tournament_id)
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

      FIXME: 戻り値とか
  """
  def create_assistants(attrs \\ %{}) do
    tournament_id = Tools.to_integer_as_needed(attrs["tournament_id"])

    Assistant
    |> where([a], a.tournament_id == ^tournament_id)
    |> Repo.delete_all()

    if Repo.exists?(from t in Tournament, where: t.id == ^tournament_id) and
         !is_nil(attrs["user_id"]) do
      not_found_users =
        attrs["user_id"]
        |> Enum.map(fn id ->
          Tools.to_integer_as_needed(id)
        end)
        |> Enum.uniq()
        |> Enum.filter(fn id ->
          if Repo.exists?(from u in User, where: u.id == ^id) do
            %Assistant{user_id: id, tournament_id: tournament_id}
            |> Repo.insert()

            false
          else
            true
          end
        end)

      {:ok, not_found_users}
    else
      {:error, :tournament_not_found}
    end
  end

  @doc """
  Returns the list of tournament_chat_topics.

  ## Examples

      iex> list_tournament_chat_topics()
      [%TournamentChatTopic{}, ...]

  """
  def list_tournament_chat_topics() do
    Repo.all(TournamentChatTopic)
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
  def get_tournament_chat_topic!(id), do: Repo.get!(TournamentChatTopic, id)

  @doc """
  Get group chat tabs in a tournament including log.
  """
  def get_tabs_by_tournament_id(tournament_id) do
    topics =
      TournamentChatTopic
      |> where([t], t.tournament_id == ^tournament_id)
      |> Repo.all()

    logs =
      TournamentChatTopicLog
      |> where([tl], tl.tournament_id == ^tournament_id)
      |> Repo.all()

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
  def create_tournament_chat_topic(attrs \\ %{}) do
    with {:ok, topic} <-
           %TournamentChatTopic{}
           |> TournamentChatTopic.changeset(attrs)
           |> Repo.insert() do
      {:ok, Map.put(topic, :tournament_id, attrs["tournament_id"])}
    else
      _ -> {:error, nil}
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
  def delete_tournament_chat_topic(%TournamentChatTopic{} = tournament_chat_topic) do
    Repo.delete(tournament_chat_topic)
  end

  @doc """
  Promotes rank of a entrant.
  勝った人のランクが上がるやつ
  """
  def promote_rank(attrs = %{"user_id" => user_id, "tournament_id" => tournament_id}, :force) do
    attrs
    |> user_exists?()
    |> tournament_exists?()
    |> tournament_start_check()
    |> case do
      {:ok, _} ->
        user_id
        |> get_entrant_by_user_id_and_tournament_id(tournament_id)
        ~> entrant
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

        update_entrant(entrant, %{rank: updated_rank})

      {:error, error} ->
        {:error, error}
    end
  end

  def promote_rank(attrs = %{"user_id" => user_id, "tournament_id" => tournament_id}) do
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

  def promote_rank(attrs = %{"team_id" => team_id, "tournament_id" => tournament_id}) do
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

  def promote_rank(attrs = %{"team_id" => team_id}, :force) do
    attrs
    |> team_exists?()
    |> tournament_exists?()
    |> tournament_start_check()
    |> case do
      {:ok, _} ->
        team_id
        |> get_team()
        ~> team
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

        update_team(team, %{rank: updated_rank})

      {:error, error} ->
        {:error, error}
    end
  end

  defp team_exists?(attrs = %{"team_id" => team_id}) do
    if Repo.exists?(from t in Team, where: t.id == ^team_id) do
      {:ok, attrs}
    else
      {:error, "undefined team"}
    end
  end

  defp get_match_list_if_possible(tournament_id) do
    tournament_id
    |> TournamentProgress.get_match_list()
    |> case do
      [] ->
        {:error, nil}

      match_list ->
        {:ok, match_list}
    end
  end

  defp update_rank(match_list, user_id, tournament_id) do
    # 対戦相手
    match_list
    |> find_match(user_id)
    |> get_opponent(user_id)
    |> case do
      {:ok, opponent} ->
        opponent
        |> Map.get("id")
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
        |> update_entrant(%{rank: updated_rank})

      {:wait, nil} ->
        {:wait, nil}

      {:error, _} ->
        {:error, nil}
    end
  end

  defp update_team_rank(match_list, team_id, tournament_id) do
    match_list
    |> find_match(team_id)
    |> get_opponent_team(team_id)
    |> case do
      {:ok, opponent} ->
        opponent
        |> Map.get("id")
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

  defp find_num_closest_exponentiation_of_two(num, acc) do
    if num > acc do
      find_num_closest_exponentiation_of_two(num, acc * 2)
    else
      div(acc, 2)
    end
  end

  defp check_exponentiation_of_two(num, base) when num == 0 do
    {true, base}
  end

  defp check_exponentiation_of_two(num, base) when num == 1 do
    {true, base}
  end

  defp check_exponentiation_of_two(num, base) do
    case rem(num, 2) do
      0 ->
        div(num, 2)
        |> check_exponentiation_of_two(base)

      _ ->
        {false, base}
    end
  end

  defp check_exponentiation_of_two(num) do
    case rem(num, 2) do
      0 ->
        div(num, 2)
        |> check_exponentiation_of_two(num)

      _ ->
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
  """
  def initialize_rank(match_list, number_of_entrant, tournament_id, count \\ 1)

  def initialize_rank(user_id, number_of_entrant, tournament_id, count)
      when is_integer(user_id) do
    final = if number_of_entrant < count, do: number_of_entrant, else: count

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

  @doc """
  Initialize rank of teams.
  """
  def initialize_team_rank(match_list, number_of_entrant, count \\ 1)

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
  def state!(tournament_id, user_id) do
    tournament_id
    |> get_tournament()
    ~> tournament
    |> is_nil()
    |> unless do
      Map.get(tournament, :is_team)
    else
      false
    end
    |> if do
      tournament_id
      |> get_team_by_tournament_id_and_user_id(user_id)
      ~> team
      |> is_nil()
      |> unless do
        team.id
      else
        user_id
      end
    else
      user_id
    end
    ~> id

    unless tournament do
      "IsFinished"
    else
      unless tournament.is_started do
        "IsNotStarted"
      else
        check_is_manager?(tournament, id, user_id)
      end
    end
  end

  # TODO: 関数名変えたい
  defp check_is_manager?(tournament, id, user_id) do
    is_manager = tournament.master_id == user_id

    tournament
    |> Map.get(:id)
    |> get_assistants()
    |> Enum.filter(fn assistant -> assistant.user_id == user_id end)
    |> (fn list -> list != [] end).()
    ~> is_assistant

    tournament
    |> Map.get(:id)
    |> get_entrants()
    |> Enum.map(& &1.user_id)
    ~> entrants

    tournament
    |> Map.get(:id)
    |> get_teams_by_tournament_id()
    |> Enum.map(fn team ->
      get_team_members_by_team_id(team.id)
    end)
    |> List.flatten()
    |> Enum.map(& &1.user_id)
    |> Enum.concat(entrants)
    |> Enum.filter(fn entrant_id ->
      entrant_id == id
    end)
    |> (fn list -> list == [] end).()
    ~> is_not_entrant

    tournament
    |> Map.get(:is_team)
    |> if do
      tournament
      |> Map.get(:id)
      |> get_team_by_tournament_id_and_user_id(user_id)
      ~> team
      |> is_nil()
      |> unless do
        team
        |> Map.get(:id)
        |> get_leader()
        |> Map.get(:user_id)
        |> Kernel.!=(user_id)
      else
        false
      end
    else
      false
    end
    ~> is_member

    cond do
      is_manager && is_not_entrant ->
        "IsManager"

      !is_manager && is_assistant && is_not_entrant ->
        "IsAssistant"

      is_member ->
        "IsMember"

      true ->
        check_has_lost?(tournament.id, id)
    end
  end

  defp check_has_lost?(tournament_id, user_id) do
    case TournamentProgress.get_match_list(tournament_id) do
      [] ->
        "IsFinished"

      match_list ->
        if has_lost?(match_list, user_id) do
          "IsLoser"
        else
          check_is_alone?(tournament_id, user_id)
        end
    end
  end

  defp check_is_alone?(tournament_id, user_id) do
    match_list = TournamentProgress.get_match_list(tournament_id)
    match = find_match(match_list, user_id)

    cond do
      is_alone?(match) -> "IsAlone"
      match == [] -> "IsLoser"
      true -> check_wait_state?(tournament_id, user_id)
    end
  end

  defp check_wait_state?(tournament_id, user_id) do
    tournament_id
    |> get_tournament()
    ~> tournament
    |> Map.get(:id)
    |> TournamentProgress.get_match_list()
    |> find_match(user_id)
    ~> match

    if tournament.is_team do
      get_opponent_team(match, user_id)
    else
      get_opponent(match, user_id)
    end
    |> elem(1)
    |> Map.get("id")
    |> TournamentProgress.get_match_pending_list(tournament_id)
    ~> opponent_pending_list

    pending_list = TournamentProgress.get_match_pending_list(user_id, tournament_id)

    cond do
      pending_list == [] ->
        "IsInMatch"

      pending_list != [] && opponent_pending_list == [] ->
        "IsWaitingForStart"

      true ->
        "IsPending"
    end
  end

  @doc """
  Returns data for tournament brackets.
  """
  def data_for_brackets(match_list) do
    {:ok, brackets} = Tournamex.brackets(match_list)
    brackets
  end

  @doc """
  Returns data with fight result for tournament brackets.
  """
  def data_with_fight_result_for_brackets(match_list) do
    {:ok, brackets} = Tournamex.brackets_with_fight_result(match_list)
    brackets
  end

  @doc """
  Construct data with game scores for brackets.
  """
  def data_with_scores_for_brackets(tournament_id) do
    match_list = TournamentProgress.get_match_list_with_fight_result_including_log(tournament_id)

    # add game_scores
    match_list
    |> List.flatten()
    |> Enum.map(fn bracket ->
      user_id = bracket["user_id"]

      win_game_scores =
        tournament_id
        |> TournamentProgress.get_best_of_x_tournament_match_logs_by_winner(user_id)
        |> Enum.map(fn log ->
          log.winner_score
        end)

      lose_game_scores =
        tournament_id
        |> TournamentProgress.get_best_of_x_tournament_match_logs_by_loser(user_id)
        |> Enum.map(fn log ->
          log.loser_score
        end)

      game_scores = win_game_scores ++ lose_game_scores

      Map.put(bracket, "game_scores", game_scores)
    end)
  end

  @doc """
  Construct data with game scores for brackets.
  """
  def data_with_scores_for_flexible_brackets(tournament_id) do
    tournament_id
    |> TournamentProgress.get_match_list_with_fight_result_including_log()
    |> Tournamex.brackets_with_fight_result()
    |> elem(1)
    ~> brackets

    # add game_scores
    brackets
    |> Enum.map(fn list ->
      inspect(list, charlists: false)

      Enum.map(list, fn bracket ->
        unless is_nil(bracket) do
          id = bracket["user_id"] || bracket["team_id"]

          tournament_id
          |> TournamentProgress.get_best_of_x_tournament_match_logs_by_winner(id)
          |> Enum.map(fn log ->
            log.winner_score
          end)
          ~> win_game_scores

          lose_game_scores =
            tournament_id
            |> TournamentProgress.get_best_of_x_tournament_match_logs_by_loser(id)
            |> Enum.map(fn log ->
              log.loser_score
            end)
            ~> lose_game_scores
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
  def get_all_tournament_records(user_id) do
    user_id = Tools.to_integer_as_needed(user_id)

    EntrantLog
    |> where([el], el.user_id == ^user_id and el.rank != 0)
    |> Repo.all()
    |> Enum.map(fn entrant_log ->
      tlog =
        TournamentLog
        |> where([tl], tl.tournament_id == ^entrant_log.tournament_id)
        |> Repo.one()

      Map.put(entrant_log, :tournament_log, tlog)
    end)
    |> Enum.filter(fn entrant_log -> entrant_log.tournament_log != nil end)
  end

  @doc """
  Scores data.
  """
  def score(tournament_id, winner_id, loser_id, winner_score, loser_score, match_index) do
    %{
      tournament_id: tournament_id,
      winner_id: winner_id,
      loser_id: loser_id,
      winner_score: winner_score,
      loser_score: loser_score,
      match_index: match_index
    }
    |> TournamentProgress.create_best_of_x_tournament_match_log()

    match_list = TournamentProgress.get_match_list_with_fight_result(tournament_id)
    match_list = Tournamex.win_count_increment(match_list, winner_id)
    TournamentProgress.delete_match_list_with_fight_result(tournament_id)
    TournamentProgress.insert_match_list_with_fight_result(match_list, tournament_id)
  end

  @doc """
  Create a team.
  TODO: 入力に対するバリデーションを行う
  """
  def create_team(tournament_id, size, leader, user_id_list) when is_list(user_id_list) do
    # 招待をすでに受けている人は弾く
    user_id_list
    |> Enum.all?(fn user_id ->
      Team
      |> join(:inner, [t], tm in TeamMember, on: t.id == tm.team_id)
      |> where([t, tm], t.tournament_id == ^tournament_id)
      |> where([t, tm], tm.user_id == ^user_id)
      |> where([t, tm], tm.is_invitation_confirmed)
      |> Repo.all()
      |> Kernel.==([])
      ~> result
    end)
    |> (fn result ->
          if result do
            {:ok, nil}
          else
            {:error, "invalid invitation to user who is already a member of another team."}
          end
        end).()
    |> case do
      {:ok, nil} ->
        tournament_id
        |> get_tournament()
        ~> tournament

        if tournament.team_size == size do
          {:ok, nil}
        else
          {:error, "invalid size"}
        end

      {:error, error} ->
        {:error, error}
    end
    |> case do
      {:ok, nil} ->
        # リーダー情報の取得
        leader_info = Accounts.get_user(leader)
        leader_name = leader_info.name
        leader_icon = leader_info.icon_path

        %Team{}
        |> Team.changeset(%{
          "tournament_id" => tournament_id,
          "size" => size,
          "name" => "#{leader_name}のチーム",
          "icon_path" => leader_icon
        })
        |> Repo.insert()
        |> case do
          {:ok, team} ->
            create_team_leader(team.id, leader)

            create_team_members(team.id, user_id_list)
            |> Enum.each(fn member ->
              create_team_invitation(member.id, leader)
            end)

            team
            |> Repo.preload(:tournament)
            |> Repo.preload(:team_member)
            |> Map.get(:team_member)
            |> Repo.preload(:user)
            |> Enum.map(fn member ->
              user = Repo.preload(member.user, :auth)
              Map.put(member, :user, user)
            end)
            ~> team_members

            team = Map.put(team, :team_member, team_members)

            {:ok, team}

          {:error, error} ->
            {:error, error}
        end

      {:error, error} ->
        {:error, error}
    end
  end

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

  defp create_team_members(team_id, user_id_list) do
    Enum.map(user_id_list, fn id ->
      %TeamMember{}
      |> TeamMember.changeset(%{"team_id" => team_id, "user_id" => id})
      |> Repo.insert()
      |> elem(1)
    end)
  end

  @doc """
  Get a team.
  """
  def get_team(team_id) do
    Team
    |> Repo.get(team_id)
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
  def get_teams_by_tournament_id(tournament_id) do
    Team
    |> where([t], t.tournament_id == ^tournament_id)
    |> Repo.all()
  end

  @doc """
  Get team by tournament_id and user_id.
  """
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
  def get_team_members_by_team_id(team_id) do
    TeamMember
    |> where([tm], tm.team_id == ^team_id)
    |> Repo.all()
    |> Repo.preload(:user)
  end

  @doc """
  Get team member by team invitation id.
  """
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
  def get_leader(team_id) do
    TeamMember
    |> where([tm], tm.team_id == ^team_id)
    |> where([tm], tm.is_leader)
    |> Repo.one()
    |> Repo.preload(:user)
  end

  @doc """
  Get teams
  """
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
      [] ->
        []

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
  def get_confirmed_teams(tournament_id) do
    Team
    |> join(:inner, [t], tm in TeamMember, on: t.id == tm.team_id)
    |> where([t, tm], t.tournament_id == ^tournament_id)
    |> where([t, tm], t.is_confirmed)
    |> preload([t, tm], :team_member)
    |> Repo.all()
    |> Enum.map(fn team ->
      team
      # FIXME: 不要？
      |> Repo.preload(:team_member)
      ~> team
      |> Map.get(:team_member)
      |> Repo.preload(:user)
      |> Enum.map(fn member ->
        user = Repo.preload(member.user, :auth)
        Map.put(member, :user, user)
      end)
      ~> team_members

      Map.put(team, :team_member, team_members)
    end)
    |> Enum.filter(fn members_in_team ->
      members_in_team.team_member
      |> Enum.all?(fn member ->
        member.is_invitation_confirmed
      end)
    end)
    |> Enum.uniq_by(fn team_with_member_info ->
      team_with_member_info.id
    end)
  end

  @doc """
  Check if the user has requested participation as a team.
  """
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
  def has_confirmed_as_team?(user_id, tournament_id) do
    tournament_id
    |> get_confirmed_teams()
    |> Enum.any?(fn team ->
      team
      |> Map.get(:id)
      |> get_team_members_by_team_id()
      |> Enum.any?(fn member ->
        member.user_id == user_id
      end)
    end)
  end

  @doc """
  Updates a team.
  """
  def update_team(%Team{} = team, attrs) do
    team
    |> Team.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Get invitations of user
  """
  def get_invitations(user_id) do
    TeamInvitation
    |> join(:inner, [ti], tm in TeamMember, on: ti.team_member_id == tm.id)
    |> where([ti, tm], tm.user_id == ^user_id)
    |> Repo.all()
  end

  def get_team_invitation(id) do
    TeamInvitation
    |> Repo.get(id)
    |> Repo.preload(:sender)
    |> Repo.preload(:team_member)
    |> Repo.preload(team_member: :user)
  end

  def team_invitation_decline(id) do 
    id = Tools.to_integer_as_needed(id)

    TeamInvitation
    |> Repo.get(id)
    |> Repo.preload(:sender)
    |> Repo.preload(:team_member)
    |> Repo.preload(team_member: :user)
    |> Repo.delete()
    |> case do
      {:ok, %TeamInvitation{} = invitation} -> 
        # delete_invitation_nofification(id)
        create_team_invitation_result_notification(invitation, false)
        {:ok, invitation}
      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Create team invitation
  """
  def create_team_invitation(team_member_id, sender_id) do
    sender = Accounts.get_user(sender_id)
    text = "#{sender.name}があなたをチームに招待しました。"

    %TeamInvitation{}
    |> TeamInvitation.changeset(%{
      "team_member_id" => team_member_id,
      "sender_id" => sender_id,
      "text" => text
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
  end

  defp push_invitation_notification(%Notification{} = _notification) do
    # TODO: push通知に関する処理を書く
  end

  @doc """
  Confirm invitation.
  """
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
          # delete_invitation_nofification(team_invitation_id)
          verify_team_as_needed(team_member.team_id)
          {:ok, team_member}
        end
      {:error, error} ->
        {:error, error}
    end
  end

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
    end
  end

  # defp delete_invitation_nofification(team_invitation_id) do
  #   %{invitation_id: team_invitation_id}
  #   |> Jason.encode!()
  #   ~> json_str

  #   Notification
  #   |> where([n], n.data == ^json_str)
  #   |> Repo.one()
  #   |> Repo.delete()
  # end

  @doc """
  Verify team.
  """
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
        take_members_into_chat(team.id)
        {:ok, team}

      {:error, error} ->
        {:error, error}
    end
  end

  defp take_members_into_chat(team_id) do
    TeamMember
    |> where([tm], tm.team_id == ^team_id)
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

  @doc """
  Delete a team
  """
  def delete_team(team_id) do
    Team
    |> Repo.get(team_id)
    |> Repo.delete()
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

  def get_push_notice_job(args, tournament_id) do
    Oban.Job
    |> where([j], j.state in ~w(available scheduled))
    |> where([j], j.args[^args] == ^tournament_id)
    |> Repo.one()
  end

  @doc """
  Create custom detail of a tournament.
  """
  def create_custom_detail(attrs \\ %{}) do
    %TournamentCustomDetail{}
    |> TournamentCustomDetail.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Get custom detail.
  """
  def get_custom_detail_by_tournament_id(tournament_id) do
    TournamentCustomDetail
    |> where([t], t.tournament_id == ^tournament_id)
    |> Repo.one()
    |> Repo.preload(:tournament)
  end

  @doc """
  Update custom detail
  """
  def update_custom_detail(detail, attrs \\ %{}) do
    detail
    |> TournamentCustomDetail.changeset(attrs)
    |> Repo.update()
  end
end

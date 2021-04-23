defmodule Milk.Tournaments do
  @moduledoc """
  The Tournaments context.
  """

  import Ecto.Query, warn: false

  use Timex
  alias Ecto.Multi
  alias Common.Tools

  alias Milk.{
    Accounts,
    Chat,
    Log,
    TournamentProgress,
    Repo
  }
  alias Milk.Accounts.{
    User,
    Relation
  }
  alias Milk.Tournaments.{
    Tournament,
    Entrant,
    Assistant,
    TournamentChatTopic
  }
  alias Milk.Log.{
    TournamentLog,
    EntrantLog,
    AssistantLog,
    TournamentChatTopicLog
  }
  alias Milk.Games.Game
  alias Milk.Chat.ChatRoom

  require Integer
  require Logger

  @typedoc """
  Tournament changeset structure.

  The types %Tournament{} and Tournaments are equivalent.
  """
  @type t :: %Tournament{}

  @doc """
  Returns the list of tournament.

  ## Examples

      iex> list_tournament()
      [%Tournament{}, ...]

  """
  def list_tournament do
    Repo.all(Tournament)
  end

  @doc """
  Returns the list of tournament for home screen.
  """
  def home_tournament() do
    Tournament
    |> where([e], e.deadline > ^Timex.now)
    |> order_by([e], asc: :event_date)
    |> Repo.all()
  end

  def home_tournament(date_offset, offset) do
    offset = Tools.to_integer_as_needed(offset)

    Tournament
    |> where([e], e.deadline > ^Timex.now and e.create_time < ^date_offset)
    |> order_by([e], asc: :event_date)
    |> offset(^offset)
    |> limit(5)
    |> Repo.all()
    |> Repo.preload(:entrant)
  end

  @doc """
  Returns the list of tournament which is filtered by "fav" for home screen.
  """
  def home_tournament_fav(user_id) do
    users =
      Relation
      |> where([r], r.follower_id == ^user_id)
      |> Repo.all()
      |> Enum.map(fn relation ->
        relation.followee_id
      end)

    Tournament
    |> where([t], t.master_id in ^users)
    |> where([e], e.deadline > ^Timex.now)
    |> order_by([e], asc: :event_date)
    |> Repo.all()
  end

  @doc """
  Returns the list of tournament which is filtered by "plan" for home screen.
  """
  def home_tournament_plan(user_id) do
    Tournament
    |> where([t], t.master_id == ^user_id)
    |> where([e], e.deadline > ^Timex.now)
    |> order_by([e], asc: :event_date)
    |> Repo.all()
  end

  @doc """
  Returns the list of tournament specified with a game id.
  """
  def game_tournament(attrs) do
    Repo.all(from t in Tournament, where: t.game_id == ^attrs["game_id"])
  end

  @doc """
  Returns tournaments of certain user.
  """
  def get_tournaments_by_master_id(user_id) do
    Repo.all(from t in Tournament, where: t.master_id == ^user_id)
  end

  def get_tournament_logs_by_master_id(user_id) do
    Repo.all(from tl in TournamentLog, where: tl.master_id == ^user_id)
    TournamentLog
    |> where([tl], tl.master_id == ^user_id)
    |> order_by([tl], asc: :event_date)
    |> Repo.all
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
  Returns ongoing tournaments of certain user.
  """
  def get_ongoing_tournaments_by_master_id(user_id) do
    Tournament
    |> where([t], t.event_date > ^Timex.now and t.master_id == ^user_id)
    |> order_by([t], asc: :event_date)
    |> Repo.all()
    |> Repo.preload(:entrant)
  end

  @doc """
  Gets a single tournament.

  Raises `Ecto.NoResultsError` if the Tournament does not exist.

  ## Examples

      iex> get_tournament!(123)
      %Tournament{}

      iex> get_tournament!(456)
      ** (Ecto.NoResultsError)

  """
  def get_tournament(id) do
    Repo.get(Tournament, id)
  end

  def get_tournament!(id) do
    Repo.get!(Tournament, id)
  end

  @doc """
  Gets single tournament by url.
  """
  def get_tournament_by_url(url) do
    Tournament
    |> where([t], t.url == ^url)
    |> Repo.one()
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
  """
  def get_participating_tournaments(user_id) do
    Entrant
    |> where([e], e.user_id == ^user_id)
    |> Repo.all()
    |> Enum.map(fn entrant ->
      get_tournament!(entrant.tournament_id)
    end)
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
      get_tournament!(entrant.tournament_id)
    end)
  end

  @doc """
  Get a list of master users' information of a tournament
  """
  def get_masters(tournament_id) do
    tournament = get_tournament!(tournament_id)

    User
    |> where([u], u.id == ^tournament.master_id)
    |> Repo.all()
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

    if Repo.exists?(from u in User, where: u.id == ^id) do
      create(params, thumbnail_path)
    else
      {:error, "Undefined User"}
    end
  end

  defp create_topic(tournament, topic, tab_index) do
    {:ok, chat_room} =
      %{
        name: tournament.name <> "-" <> topic,
        member_count: tournament.count
      }
      |> Chat.create_chat_room()
    %TournamentChatTopic{tournament_id: tournament.id, chat_room_id: chat_room.id}
    |> TournamentChatTopic.changeset(%{"topic_name" => topic, "tab_index" => tab_index})
  end

  # TODO: エラーハンドリング
  def update_topic(tournament, current_tabs, new_tabs) do
    currentIds = Enum.map(current_tabs, fn tab ->
        tab.chat_room_id
    end)
    newIds = Enum.map(new_tabs, fn tab ->
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
        topic = Repo.one(from c in TournamentChatTopic, where: c.chat_room_id == ^tab["chat_room_id"])
        update_tournament_chat_topic(topic, %{topic_name: tab["topic_name"], tab_index: tab["tab_index"]})
      else
        Repo.insert(create_topic(tournament, tab["topic_name"], tab["tab_index"]))
      end
    end)
  end

  defp create(attrs, thumbnail_path) do
    master_id = Tools.to_integer_as_needed(attrs["master_id"])
    platform_id = Tools.to_integer_as_needed(attrs["platform"])

    Multi.new()
    |> Multi.insert(:tournament,
      %Tournament{
        master_id: master_id,
        game_id: attrs["game_id"],
        thumbnail_path: thumbnail_path,
        platform_id: platform_id
      }
      |> Tournament.create_changeset(attrs)
    )
    |> Multi.insert(:group_topic, fn %{tournament: tournament} -> create_topic(tournament, "Group", 0) end)
    |> Multi.insert(:notification_topic, fn %{tournament: tournament} -> create_topic(tournament, "Notification", 1) end)
    |> Multi.insert(:q_and_a_topic, fn %{tournament: tournament} -> create_topic(tournament, "Q&A", 2) end)
    |> Repo.transaction()
    |> case do
      {:ok, tournament} ->
        {:ok, tournament.tournament}
      {:error, error} ->
        {:error, error.errors}
      _ ->
        {:error, nil}
    end
  end

  @doc """
  Verify password.
  """
  def verify?(tournament_id, password) do
    tournament = get_tournament!(tournament_id)
    IO.inspect(password, label: :password)
    IO.inspect(tournament.password, label: :hash)
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
    attrs =
      unless is_nil(attrs["platform"]) do
        Map.put(attrs, "platform_id", attrs["platform"])
      else
        attrs
      end

    if !attrs["game_id"] or Repo.exists?(from g in Game, where: g.id == ^attrs["game_id"]) do
      tournament
      |> IO.inspect()
      |> Tournament.changeset(attrs)
      |> Repo.update()
      |> case do
        {:ok, tournament} ->
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

  @doc """
  Renew match list as needed.
  """
  def trim_match_list_as_needed(tournament_id) do
    match_list_len =
      tournament_id
      |> TournamentProgress.get_match_list()
      |> case do
        [{_, match_list}] when is_list(match_list) -> match_list_length(match_list)
        _ -> 0
      end

    match_list_with_fight_result_len =
      tournament_id
      |> TournamentProgress.get_match_list_with_fight_result()
      |> case do
        [{_, match_list}] when is_list(match_list) -> match_list_length(match_list)
        _ -> 0
      end

    if match_list_with_fight_result_len > 16 and match_list_len <= 16 do
      [{_, new_list}] = TournamentProgress.get_match_list(tournament_id)
      TournamentProgress.delete_match_list_with_fight_result(tournament_id)
      TournamentProgress.insert_match_list_with_fight_result(new_list, tournament_id)
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
    tournament = Repo.one(from t in Tournament, left_join: a in assoc(t, :assistant),
    left_join: e in assoc(t, :entrant), where: t.id == ^id,
    preload: [assistant: a, entrant: e])

    entrant = Enum.map(tournament.entrant, fn x -> %{rank: x.rank, user_id: x.user_id,
      tournament_id: x.tournament_id, update_time: x.update_time, create_time: x.create_time} end)
    if entrant, do: Repo.insert_all(EntrantLog, entrant)

    assistant = Enum.map(tournament.assistant, fn x -> %{user_id: x.user_id, tournament_id: x.tournament_id,
    update_time: x.update_time, create_time: x.create_time} end)
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
    Repo.one(from e in Entrant, where: ^tournament_id == e.tournament_id and ^user_id == e.user_id)
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
    |> user_exist_check()
    |> tournament_exist_check()
    |> not_entrant_check()
    |> insert()
    |> case do
        {:ok, entrant} -> join_tournament_chat_room(entrant, attrs)
        {:error, _, error, _data} when is_bitstring(error) -> {:error, error}
        {:error, _, error, _data} -> {:multierror, error.errors}
        {:error, error} -> {:error,error}
        _ -> {:error, nil}
    end
  end

  defp user_exist_check(attrs) do
    with :false <- is_nil(attrs["user_id"]),
    :true <- Repo.exists?(from u in User, where: u.id == ^attrs["user_id"]) do
      {:ok, attrs}
    else
      _ -> {:error, "undefined user"}
    end
  end

  defp not_entrant_check({:ok, attrs}) do
    unless Repo.exists?(from e in Entrant, where: e.tournament_id == ^attrs["tournament_id"] and e.user_id == ^attrs["user_id"]) do
      {:ok, attrs}
    else
      {:error, "Already joined"}
    end
  end

  defp not_entrant_check({:error, error})do
    {:error, error}
  end

  defp tournament_exist_check({:ok, attrs}) do
    if Repo.exists?(from t in Tournament, where: t.id == ^attrs["tournament_id"]) do
      {:ok, attrs}
    else
      {:error, "undefined tournament"}
    end
  end

  defp tournament_exist_check({:error, error})do
    {:error, error}
  end

  defp insert({:ok, attrs}) do
    user_id = if is_binary(attrs["user_id"]) do
      String.to_integer(attrs["user_id"])
    else
      attrs["user_id"]
    end
    tournament_id = if is_binary(attrs["tournament_id"]) do
      String.to_integer(attrs["tournament_id"])
    else
      attrs["tournament_id"]
    end

    Multi.new()
    |> Multi.run(:tournament, fn repo, _ ->
      case repo.one(from t in Tournament, where: t.id == ^tournament_id and t.capacity > t.count) do
      (%Tournament{} = t) -> {:ok, t}
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

  defp insert({:error, error})do
    {:error, error}
  end

  # TODO: リファクタリングできそう
  defp join_tournament_chat_room(entrant, attrs) do
    user_id = if is_binary(attrs["user_id"]) do
      String.to_integer(attrs["user_id"])
    else
      attrs["user_id"]
    end

    result =
      Chat.get_chat_rooms_by_tournament_id(entrant.tournament.id)
      |> Enum.reduce({:ok, nil}, fn (chat_room, _acc) ->
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
    case entrant
    |> Entrant.changeset(attrs)
    |> Repo.update() do
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

    unless Repo.exists?(from e in Entrant, where: e.tournament_id == ^tournament_id and e.user_id == ^user_id) do
      {:error, "entrant not found"}
    else
      entrant =
        Entrant
        |> where([e], e.tournament_id == ^tournament_id and e.user_id == ^user_id)
        |> Repo.one
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
    EntrantLog.changeset(%EntrantLog{}, map)
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
    :false <- is_nil(entrant) do
      Map.get(entrant, :rank)
    else
      :true -> {:error, "entrant is not found"}
    end
  end

  @doc """
  Delete loser.
  TODO: エラーハンドリング
  """
  def delete_loser_process(tournament_id, loser_list) do
    [{_, match_list}] = TournamentProgress.get_match_list(tournament_id)

    match_list
    |> find_match(hd(loser_list))
    |> Enum.each(fn user_id ->
      TournamentProgress.delete_match_pending_list({user_id, tournament_id})
      TournamentProgress.delete_fight_result({user_id, tournament_id})
    end)

    renew_match_list(tournament_id, match_list, loser_list)
    [{_, updated_match_list}] = TournamentProgress.get_match_list(tournament_id)
    renew_match_list_with_fight_result(tournament_id, loser_list)
    unless is_integer(updated_match_list), do: trim_match_list_as_needed(tournament_id)

    updated_match_list
  end

  defp renew_match_list_with_fight_result(tournament_id, [loser]) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)

    TournamentProgress.renew_match_list_with_fight_result(loser, tournament_id)
  end

  defp renew_match_list(tournament_id, match_list, loser_list) do
    unless is_nil(match_list) do
      promote_winners_by_loser(tournament_id, match_list, loser_list)
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

  def promote_winners_by_loser(tournament_id, match_list, losers) when is_list(losers) do
    Enum.each(losers, fn loser ->
      {:ok, opponent} =
        match_list
        |> find_match(loser)
        |> get_opponent(loser)

      promote_rank(%{"tournament_id" => tournament_id, "user_id" => opponent["id"]})
    end)
  end

  def promote_winners_by_loser(tournament_id, match_list, loser) do
    {:ok, opponent} =
      match_list
      |> find_match(loser)
      |> get_opponent(loser)

    promote_rank(%{"tournament_id" => tournament_id, "user_id" => opponent["id"]})
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
    inspect(map)
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
      |> (fn the_other ->
        if is_integer(the_other) do
          opponent =
            Accounts.get_user(the_other)
            |> atom_user_map_to_string_map()
          {:ok, opponent}
        else
          {:wait, nil}
        end
      end).()
    else
      {:error, "opponent does not exist"}
    end
  end

  def get_opponent(match, user_id, :promote) do
    a =
      match
      |> Enum.filter(fn x ->
        inspect(x)
        x.user_id != user_id
      end)
      |> hd()
    inspect(a)

    a.user_id
    |> Accounts.get_user()
    |> atom_user_map_to_string_map()
  end

  defp atom_user_map_to_string_map(%User{} = user) do
    %{
      "id" => user.id,
      "icon_path" => user.icon_path,
      "id_for_show" => user.id_for_show,
      "name" => user.name,
    }
  end

  @doc """
  Checks whether the user have to wait.
  """
  def is_alone?(match) do
    Enum.filter(match, &(is_list(&1))) != []
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
    nil_check_on_start?(master_id, tournament_id)
    |> check_entrant_number(tournament_id)
    |> fetch_tournament(master_id, tournament_id)
    |> start()
  end

  defp nil_check_on_start?(master_id, tournament_id) do
    if !is_nil(master_id) and !is_nil(tournament_id) do
      {:ok, nil}
    else
      {:error, "master_id or tournament_id is nil"}
    end
  end

  defp check_entrant_number(check, tournament_id) do
    case check do
      {:ok, _} ->
        if number_of_entrants(tournament_id) > 1 do
          {:ok, nil}
        else
          delete_tournament(tournament_id)
          {:error, "too few entrants"}
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp number_of_entrants(tournament_id) do
    Entrant
    |> where([e], e.tournament_id == ^tournament_id)
    |> Repo.all()
    |> length()
  end

  defp fetch_tournament(check, master_id, tournament_id) do
    case check do
      {:ok, nil} ->
        tournament =
          Tournament
          |> where([t], t.master_id == ^master_id and t.id == ^tournament_id)
          |> Repo.one()
        unless is_nil(tournament) do
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
  Finish a tournament.
  トーナメントを終了させ、終了したトーナメントをログの方に移行して削除する
  """
  def finish(tournament_id, winner_user_id) do
    case finish_entrants(tournament_id) do
      :ok -> finish_tournament(tournament_id, winner_user_id)
      :error -> false
      _ -> false
    end
  end

  defp finish_tournament(tournament_id, winner_user_id) do
    {:ok, tournament} =
      tournament_id
      |> get_tournament!()
      |> delete_tournament()

    tournament
    |> atom_tournament_map_to_string_map(winner_user_id)
    |> Log.create_tournament_log()
    |> case do
      {:ok, _tournament_log} -> true
      {:error, _} -> false
    end
  end

  defp finish_entrants(tournament_id) do
    tournament_id
    |> get_entrants()
    |> Enum.each(fn entrant ->
      delete_entrant(entrant)
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
  Put value on brackets.
  """
  def put_value_on_brackets(match_list, key, value) do
    Tournamex.put_value_on_brackets(match_list, key, value)
  end

  @doc """
  Returns the list of assistant.

  ## Examples

      iex> list_assistant()
      [%Assistant{}, ...]

  """
  def list_assistant() do
    Repo.all(Assistant)
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

  def get_assistants(id) do
    Assistant
    |> where([a], a.tournament_id == ^id)
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
    get_entrants(tournament_id)
    |> Enum.filter(fn entrant ->
      TournamentProgress.get_match_pending_list({entrant.user_id, tournament_id}) != []
    end)
    |> Enum.map(fn entrant ->
      Accounts.get_user(entrant.user_id)
    end)
  end

  @doc """
  Get users waiting for fighting ones.
  """
  def get_waiting_users(tournament_id) do
    fighting_users = get_fighting_users(tournament_id)

    tournament_id
    |> get_entrants()
    |> Enum.filter(fn entrant ->
      [{_, match_list}] = TournamentProgress.get_match_list(tournament_id)
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

  @doc """
  Creates a assistant.

  ## Examples

      iex> create_assistant(%{field: value})
      {:ok, %Assistant{}}

      iex> create_assistant(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

      FIXME: 戻り値とか
  """
  def create_assistant(attrs \\ %{}) do
    tournament_id = Tools.to_integer_as_needed(attrs["tournament_id"])

    Assistant
    |> where([a], a.tournament_id == ^tournament_id)
    |> Repo.delete_all()

    if Repo.exists?(from t in Tournament, where: t.id == ^tournament_id) and !is_nil(attrs["user_id"]) do
      not_found_users =
        attrs["user_id"]
        |> Enum.map(fn id ->
          if is_binary(id) do
            String.to_integer(id)
          else
            id
          end
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

        if Enum.empty?(not_found_users) do
          :ok
        else
          {:ok, not_found_users}
        end
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
  Get group chat tabs in a tournament.
  """
  def get_tabs_by_tournament_id(tournament_id) do
    TournamentChatTopic
    |> where([t], t.tournament_id == ^tournament_id)
    |> Repo.all()
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
  def promote_rank(attrs \\ %{}) do
    user_id = attrs["user_id"]
    tournament_id = attrs["tournament_id"]

    attrs
    |> user_exist_check()
    |> tournament_exist_check()
    |> tournament_start_check()
    |> case do
      {:ok, attrs} ->
        get_match_list_if_possible(tournament_id)
      {:error, error} ->
        {:error, error}
    end
    |> case do
      {:ok, match_list} -> update_rank(match_list, user_id, tournament_id)
      {:error, error} -> {:error, error}
    end
  end

  defp get_match_list_if_possible(tournament_id) do
    tournament_id
    |> TournamentProgress.get_match_list()
    |> case do
      [] ->
        {:error, nil}
      list ->
        [{_, match_list}] = list
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
        opponent =
          opponent
          |> Map.get("id")
          |> get_entrant_by_user_id_and_tournament_id(tournament_id)
        opponents_rank = Map.get(opponent, :rank)

        user =
          user_id
          |> get_entrant_by_user_id_and_tournament_id(tournament_id)

          user
          |> Map.get(:rank)
          |> case do
            rank when rank > opponents_rank -> update_entrant(opponent, %{rank: rank})
            rank when rank < opponents_rank -> update_entrant(user, %{rank: opponents_rank})
            _ ->
          end

        {bool, rank} =
          opponent
          |> Map.get(:rank)
          |> check_exponentiation_of_two()
        updated =
          bool
          |> if do
            div(rank, 2)
          else
            find_num_closest_exponentiation_of_two(rank)
          end
        entrant = get_entrant_by_user_id_and_tournament_id(user_id, tournament_id)
        entrant
        |> update_entrant(%{rank: updated})
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
  Initialize rank of a user.
  """
  def initialize_rank(match_list, number_of_entrant, tournament_id, count \\ 1)
  def initialize_rank(match_list, number_of_entrant, tournament_id, count) when is_integer(match_list) do
    final = if number_of_entrant < count, do: number_of_entrant, else: count

    {:ok, entrant} =
      get_entrant_by_user_id_and_tournament_id(match_list, tournament_id)
      |> update_entrant(%{rank: final})

    entrant
  end
  def initialize_rank(match_list, number_of_entrant, tournament_id, count) do
    Enum.map(match_list, fn x -> initialize_rank(x, number_of_entrant, tournament_id, count *2) end)
  end

  @doc """
  Checks tournament state.
  # FIXME: 大会には参加していない主催者のstateを追加する
  """
  def state!(tournament_id, user_id) do
    tournament = get_tournament(tournament_id)

    unless tournament do
      "IsFinished"
    else
      unless tournament.is_started do
        "IsNotStarted"
      else
        check_is_manager?(tournament, user_id)
      end
    end
  end

  defp check_is_manager?(tournament, user_id) do
    is_manager = tournament.master_id == user_id
    is_not_entrant =
      tournament.id
      |> get_entrants()
      |> Enum.filter(fn entrant -> entrant.user_id == user_id end)
      |> (fn list -> list == [] end).()

    if is_manager && is_not_entrant do
      "IsManager"
    else
      check_has_lost?(tournament.id, user_id)
    end
  end

  defp check_has_lost?(tournament_id, user_id) do
    case TournamentProgress.get_match_list(tournament_id) do
      [] ->
        "IsFinished"
      [{_, match_list}] ->
        if has_lost?(match_list, user_id) do
          "IsLoser"
        else
          check_is_alone?(tournament_id, user_id)
        end
    end
  end

  defp check_is_alone?(tournament_id, user_id) do
    {_, match_list} =
      TournamentProgress.get_match_list(tournament_id)
      |> hd()
    match = find_match(match_list, user_id)

    if is_alone?(match) do
      "IsAlone"
    else
      check_wait_state?(tournament_id, user_id)
    end
  end

  defp check_wait_state?(tournament_id, user_id) do
    {_, match_list} =
      TournamentProgress.get_match_list(tournament_id)
      |> hd()
    match = find_match(match_list, user_id)
    # FIXME: エラーハンドリング
    {:ok, opponent} = get_opponent(match, user_id)
    pending_list = TournamentProgress.get_match_pending_list({user_id, tournament_id})
    opponent_pending_list = TournamentProgress.get_match_pending_list({opponent["id"], tournament_id})

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
end

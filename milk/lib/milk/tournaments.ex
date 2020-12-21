defmodule Milk.Tournaments do
  @moduledoc """
  The Tournaments context.
  """

  import Ecto.Query, warn: false

  use Timex

  alias Milk.Ets
  alias Milk.Repo
  alias Ecto.Multi

  alias Milk.Accounts
  alias Milk.Accounts.{User, Relation}
  alias Milk.Tournaments.{Tournament, Entrant, Assistant, TournamentChatTopic}
  alias Milk.Log.{TournamentLog, EntrantLog, AssistantLog, TournamentChatTopicLog}
  alias Milk.Games.Game
  alias Milk.Chat
  alias Milk.Log
  alias Common.Tools
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

  @doc """
  Returns ongoing tournaments of certain user.
  """
  def get_ongoing_tournaments_by_master_id(user_id) do
    Repo.all(from t in Tournament, where: t.master_id == ^user_id)
    |> Enum.filter(fn tournament ->
      date =
        tournament.event_date
        |> DateTime.to_unix()

      now =
        DateTime.utc_now()
        |> DateTime.to_unix()

      now < date
    end)
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
  def get_tournament(id), do: Repo.get(Tournament, id)
  def get_tournament!(id), do: Repo.get!(Tournament, id)

  @doc """
  Get tournaments which the user participating in.
  """
  def get_participating_tournaments!(user_id) do
    Entrant
    |> where([e], e.user_id == ^user_id)
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

  defp create_topic(tournament, topic) do
    {:ok, chat_room} =
      %{
        name: tournament.name <> "-" <> topic,
        member_count: tournament.count
      }
      |> Chat.create_chat_room()
    %TournamentChatTopic{tournament_id: tournament.id, chat_room_id: chat_room.id}
    |> TournamentChatTopic.changeset(%{"topic_name" => topic})
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
      |> Tournament.changeset(attrs)
    )
    |> Multi.insert(:group_topic, fn %{tournament: tournament} -> create_topic(tournament, "Group") end)
    |> Multi.insert(:notification_topic, fn %{tournament: tournament} -> create_topic(tournament, "Notification") end)
    |> Multi.insert(:q_and_a_topic, fn %{tournament: tournament} -> create_topic(tournament, "Q&A") end)
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
  Updates a tournament.

  ## Examples

      iex> update_tournament(tournament, %{field: new_value})
      {:ok, %Tournament{}}

      iex> update_tournament(tournament, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tournament(%Tournament{} = tournament, attrs) do
    if (!attrs["game_id"] or Repo.exists?(from g in Game, where: g.id == ^attrs["game_id"])) do
      case tournament
      |> Tournament.changeset(attrs)
      |> Repo.update() do
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

    TournamentLog.changeset(%TournamentLog{}, Map.from_struct(tournament))
    |> Repo.insert()

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

  defp get_entrant_by_user_id_and_tournament_id(user_id, tournament_id) do
    Repo.one(from e in Entrant, where: ^tournament_id == e.tournament_id and ^user_id == e.user_id)
  end

  @doc """
  Get entrants of a tournament.
  """
  def get_entrants(id) do
    Entrant
    |> where([e], e.tournament_id == ^id)
    |> Repo.all()
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
        {:error,_, error, _data} when is_bitstring(error) -> {:error, error}
        {:error, _, error, _data} -> {:multierror, error.errors}
        {:error,error} -> {:error,error}
        _ -> {:error, nil}
    end
  end

  defp user_exist_check(attrs) do
    with :false <- is_nil(attrs["user_id"]),
    :true <- Repo.exists?(from u in User, where: u.id == ^attrs["user_id"]) do
      {:ok,attrs}
    else
      _ -> {:error,"undefined user"}
    end
  end

  defp not_entrant_check({:ok, attrs})do
    unless Repo.exists?(from e in Entrant, where: e.tournament_id == ^attrs["tournament_id"] and e.user_id == ^attrs["user_id"]) do
      {:ok, attrs}
    else
      {:error,"Already joined"}
    end
  end

  defp not_entrant_check({:error, error})do
    {:error,error}
  end

  defp tournament_exist_check({:ok, attrs}) do
    if Repo.exists?(from t in Tournament, where: t.id == ^attrs["tournament_id"]) do
      {:ok, attrs}
    else
      {:error, "undefined tournament"}
    end
  end

  defp tournament_exist_check({:error,error})do
    {:error,error}
  end

  defp insert({:ok,attrs}) do
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

  defp insert({:error,error})do
    {:error,error}
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
    EntrantLog.changeset(%EntrantLog{}, Map.from_struct(entrant))
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
    with entrant <- Repo.one(from e in Entrant, where: e.tournament_id == ^tournament_id and e.user_id == ^user_id),
    :false <- is_nil(entrant) do
      Map.get(entrant, :rank)
    else
      :true -> {:error, "entrant is not found"}
    end
  end

  @doc """
  Delete a loser in a matchlist
  """
  def delete_loser(list, loser) when is_integer(loser) do
    delete_loser(list, [loser])
  end

  def delete_loser([a, b], loser) when is_integer(a) and is_integer(b) do
    list = [a, b] -- loser
    if length(list) == 1, do: hd(list), else: list
  end

  def delete_loser(list, loser) do
    case list do
      [[a, b], [c, d]] ->
        [delete_loser([a, b], loser), delete_loser([c, d], loser)]
      [a, [b, c]] when is_integer(a) and [a] == loser ->
        [b, c]
      [a, [b, c]] ->
        [a, delete_loser([b, c], loser)]
      [[a, b], c] when is_integer(c) and [c] == loser ->
        [a, b]
      [[a, b], c] ->
        [delete_loser([a, b], loser), c]
      [a, b] ->
        delete_loser([a, b], loser)
      _ -> raise "Bad Argument"
    end
  end

  @doc """
  Finds a 1v1 match of given id and match list.
  """
  def find_match(list, id, result \\ []) do
    Enum.reduce(list, result, fn x, acc ->
      y = process_entrant(x)

      case y do
        y when is_list(y) -> find_match(y, id, acc)
        y when is_integer(y) and y == id -> acc ++ list
        y when is_integer(y) -> acc
      end
    end)
  end

  # FIXME: 名前が微妙
  defp process_entrant(%Entrant{} = map) do
    inspect(map)
    map.user_id
  end

  defp process_entrant(id), do: id

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
  Judges whether the user have to wait.
  """
  def is_alone?(match) do
    Enum.filter(match, &(is_list(&1))) != []
  end

  @doc """
  Starts a tournament.
  """
  def start(master_id, tournament_id) do
    with :false <- is_nil(master_id) or is_nil(tournament_id),
    tournament <- Tournament
      |> where([t], t.master_id == ^master_id and t.id == ^tournament_id)
      |> Repo.one(),
      :false <- is_nil(tournament) do
      unless tournament.is_started do
        tournament
        |> Tournament.changeset(%{is_started: true})
        |> Repo.update()
      else
        {:error, nil}
      end
    else
      _ -> {:error, "unexpected error"}
    end
  end

  @doc """
  Finish a tournament.
  トーナメントを終了させ、終了したトーナメントをログの方に移行して削除する
  """
  def finish(tournament_id, winner_user_id) do
    # FIXME: user_idを使って認証する処理を書いてない

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

  defp atom_tournament_map_to_string_map(%Tournament{} = tournament, winner_id) do
    %{
      "id" => tournament.id,
      "name" => tournament.name,
      "type" => tournament.type,
      "deadline" => tournament.deadline,
      "url" => tournament.url,
      "description" => tournament.description,
      "event_date" => tournament.event_date,
      "game_id" => tournament.game_id,
      "winner_id" => winner_id,
      "capacity" => tournament.capacity
    }
  end

  @doc """
  Generate a matchlist.
  """
  def generate_matchlist(list) do
    unless is_list(list) do
      {:error, "Argument is not list"}
    else
      list
      |> priv_generate_matchlist()
      |> case do
        list when is_list(list) -> {:ok, list}
        tuple when is_tuple(tuple) -> tuple
        scala -> {:ok, [scala]}
      end
    end
  end

  defp priv_generate_matchlist(list) when list != [] do
    shuffled = list |> Enum.shuffle()
    case(length(shuffled)) do
    1 ->
      shuffled |> hd()
    2 -> shuffled
    _ ->
      b = Enum.slice(shuffled, 0..trunc(length(shuffled)/2 -1))
      |> priv_generate_matchlist()

      c = Enum.slice(shuffled, trunc(length(shuffled)/2)..length(shuffled)-1)
      |> priv_generate_matchlist()

      [b,c]
    end
  end
  defp priv_generate_matchlist([]), do: {:error, "参加者がいません"}

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

  def get_assistants(id) do
    Assistant
    |> where([a], a.tournament_id == ^id)
    |> Repo.all()
  end

  def get_user_info_of_assistant(%Assistant{} = assistant) do
    User
    |> where([u], u.id == ^assistant.user_id)
    |> Repo.one()
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

    if Repo.exists?(from t in Tournament, where: t.id == ^tournament_id) do
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
  """
  def promote_rank(attrs \\ %{}) do
    attrs
    |> user_exist_check()
    |> tournament_exist_check()
    |> tournament_start_check()
    |> case do
      {:ok, attrs} ->
        entrant =
          attrs["user_id"]
          |> get_entrant_by_user_id_and_tournament_id(attrs["tournament_id"])
        {_num, match_list} =
          attrs["tournament_id"]
          |> Ets.get_match_list()
          |> hd()
        # 対戦相手
        opponent =
          match_list
          |> find_match(attrs["user_id"])
          |> get_opponent(attrs["user_id"], :promote)
          |> Map.get("id")
          |> get_entrant_by_user_id_and_tournament_id(attrs["tournament_id"])
        opponents_rank = Map.get(opponent, :rank)

        user =
          attrs["user_id"]
          |> get_entrant_by_user_id_and_tournament_id(attrs["tournament_id"])

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
            rank
            |> find_num_closest_exponentiation_of_two()
          end
        entrant
        |> update_entrant(%{rank: updated})
      {:error, error} -> {:error, error}
    end
  end

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
end

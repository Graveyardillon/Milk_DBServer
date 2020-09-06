defmodule Milk.Tournaments do
  @moduledoc """
  The Tournaments context.
  """

  import Ecto.Query, warn: false
  alias Milk.Repo
  alias Ecto.Multi

  alias Milk.Tournaments.Tournament
  alias Milk.Tournaments.Entrant
  alias Milk.Tournaments.Assistant
  alias Milk.Tournaments.TournamentChatTopic
  alias Milk.Games.Game
  alias Milk.Chat
  alias Milk.Chat.ChatRoom
  alias Milk.Chat.ChatMember
  alias Milk.Accounts.User
  alias Milk.Log.{TournamentLog, EntrantLog, AssistantLog, TournamentChatTopicLog}

  require Logger

  @doc """
  Returns the list of tournament.

  ## Examples

      iex> list_tournament()
      [%Tournament{}, ...]

  """
  def list_tournament do
    Repo.all(Tournament)
  end

  def game_tournament(attrs) do
    Repo.all(from t in Tournament, where: t.game_id == ^attrs["game_id"])
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
  def get_tournament!(id), do: Repo.get!(Tournament, id)

  @doc """
  Creates a tournament.

  ## Examples

      iex> create_tournament(%{field: value})
      {:ok, %Tournament{}}

      iex> create_tournament(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tournament(attrs \\ %{}) do
    master_repo = Repo.exists?(from u in User, where: u.id == ^attrs["master_id"])

    if master_repo do
      create_tournament(:notnil, attrs)
    else
      create_tournament(:nil, attrs)
    end

    # gameをチェックしない

    # game_repo = Repo.exists?(from u in Game, where: u.id == ^attrs["game_id"])
    
    # if master_repo and game_repo do
    #   create_tournament(:notnil, attrs)
    # else
    #   create_tournament(:nil, attrs)
    # end
  end

  defp create_tournament(:notnil, attrs) do

    master_id = String.to_integer(attrs["master_id"])

    tournament_struct = %Tournament{master_id: master_id, game_id: attrs["game_id"]}
    tournament = Multi.new()
                 |> Multi.insert(:tournament, Tournament.changeset(tournament_struct, attrs))
                 |> Multi.insert(:group_topic, fn %{tournament: tournament} ->
                   room_params = %{
                     name: tournament.name <> "-" <> "Group",
                     member_count: tournament.count,
                   }
                   {:ok, chat_room} = Chat.create_chat_room(room_params)
                   topic = %{"topic_name" => "Group"}

                   %TournamentChatTopic{tournament_id: tournament.id, chat_room_id: chat_room.id}
                   |> TournamentChatTopic.changeset(topic)
                 end)
                 |> Multi.insert(:notification_topic, fn %{tournament: tournament} ->
                   room_params = %{
                     name: tournament.name <> "-" <> "Notification",
                     member_count: tournament.count,
                   }
                   {:ok, chat_room} = Chat.create_chat_room(room_params)
                   topic = %{"topic_name" => "Notification"}

                   %TournamentChatTopic{tournament_id: tournament.id, chat_room_id: chat_room.id}
                   |> TournamentChatTopic.changeset(topic)
                 end)
                 |> Multi.insert(:q_and_a_topic, fn %{tournament: tournament} ->
                   room_params = %{
                     name: tournament.name <> "-" <> "Q&A",
                     member_count: tournament.count,
                   }
                   {:ok, chat_room} = Chat.create_chat_room(room_params)
                   topic = %{"topic_name" => "Q&A"}

                   %TournamentChatTopic{tournament_id: tournament.id, chat_room_id: chat_room.id}
                   |> TournamentChatTopic.changeset(topic)
                 end)
                 |> Repo.transaction()

    case tournament do
      {:ok, tournament} ->
        {:ok, tournament.tournament}
      {:error, error} ->
        {:error, error.errors}
      _ ->
        {:error, nil}
    end
  end

  defp create_tournament(:nil, attrs), do: {:error, nil}

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
    |> Repo.insert
    |> IO.inspect
    Repo.delete(tournament)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tournament changes.

  ## Examples

      iex> change_tournament(tournament)
      %Ecto.Changeset{data: %Tournament{}}

  """
  def change_tournament(%Tournament{} = tournament, attrs \\ %{}) do
    Tournament.changeset(tournament, attrs)
  end

  @doc """
  Returns the list of entrant.

  ## Examples

      iex> list_entrant()
      [%Entrant{}, ...]

  """
  def list_entrant do
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

  @doc """
  Creates a entrant.

  ## Examples

      iex> create_entrant(%{field: value})
      {:ok, %Entrant{}}

      iex> create_entrant(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_entrant(attrs \\ %{}) do
    if Repo.exists?(from u in User, where: u.id == ^attrs["user_id"])
      and not Repo.exists?(from e in Entrant, where: e.tournament_id == ^attrs["tournament_id"] and e.user_id == ^attrs["user_id"]) do 
      result =  Multi.new()
                |> Multi.run(:tournament, fn repo, _ ->
                  {:ok, repo.get(Tournament, attrs["tournament_id"])}
                end)
                |> Multi.insert(:entrant, fn _ ->
                  %Entrant{user_id: attrs["user_id"], tournament_id: attrs["tournament_id"]}
                  |> Entrant.changeset(attrs)
                end)
                |> Multi.update(:update, fn %{tournament: tournament} ->
                  Tournament.changeset(tournament, %{count: tournament.count + 1}) 
                end)
                |> Repo.transaction()

      case result do
        {:ok, entrant} -> join_tournament_chat_room(entrant, attrs)
        {:error, _, error, data} -> {:error, error.errors}
        _ -> {:error, nil}
      end
    else
      Logger.error("duplicate entrant")
      {:error, nil}
    end
  end

  defp join_tournament_chat_room(entrant, attrs) do
    result = Chat.get_chat_rooms_by_tournament_id(entrant.tournament.id)
             |> Enum.reduce({:ok, nil}, fn (chat_room, acc) ->
               join_params = %{
                 "user_id" => attrs["user_id"],
                 "chat_room_id" => chat_room.id,
                 "authority" => 0
               }
               with {:ok, chat_member} <- Chat.create_chat_member(join_params) do
                 IO.inspect("join_tournament_chat_room")
                 IO.inspect(chat_member)
                 acc = {:ok, chat_member}
               else
                 {:error, reason} -> 
                  acc = {:error, reason}
                 _ -> 
                  acc = {:error, nil}
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
  def delete_entrant(%Entrant{} = entrant) do
    EntrantLog.changeset(%EntrantLog{}, Map.from_struct(entrant))
    |> Repo.insert()
    tournament = Repo.get(Tournament, entrant.tournament_id)
    Tournament.changeset(tournament, %{count: tournament.count -1})
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
  Returns the list of assistant.

  ## Examples

      iex> list_assistant()
      [%Assistant{}, ...]

  """
  def list_assistant do
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

  @doc """
  Creates a assistant.

  ## Examples

      iex> create_assistant(%{field: value})
      {:ok, %Assistant{}}

      iex> create_assistant(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_assistant(attrs \\ %{}) do
    if (Repo.exists?(from u in User, where: u.id == ^attrs["user_id"]) 
    and Repo.exists?(from t in Tournament, where: t.id == ^attrs["tournament_id"])) do
      case %Assistant{user_id: attrs["user_id"], tournament_id: attrs["tournament_id"]}
      |> Repo.insert() do
      {:ok, assistant} ->
        {:ok, assistant}
      {:error, error} ->
        {:error, error.errors}
      _ ->
        {:error, nil}
      end
    end
  end

  @doc """
  Updates a assistant.

  ## Examples

      iex> update_assistant(assistant, %{field: new_value})
      {:ok, %Assistant{}}

      iex> update_assistant(assistant, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_assistant(%Assistant{} = assistant, attrs) do
    case assistant
    |> Assistant.changeset(attrs)
    |> Repo.update() do
      {:ok, assistant} ->
        {:ok, assistant}
      {:error, error} ->
        {:error, error.errors}
      _ ->
        {:error, nil}
    end
  end

  @doc """
  Deletes a assistant.

  ## Examples

      iex> delete_assistant(assistant)
      {:ok, %Assistant{}}

      iex> delete_assistant(assistant)
      {:error, %Ecto.Changeset{}}

  """
  def delete_assistant(%Assistant{} = assistant) do
    AssistantLog.changeset(%AssistantLog{}, Map.from_struct(assistant))
    |> Repo.insert()
    Repo.delete(assistant)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking assistant changes.

  ## Examples

      iex> change_assistant(assistant)
      %Ecto.Changeset{data: %Assistant{}}

  """
  def change_assistant(%Assistant{} = assistant, attrs \\ %{}) do
    Assistant.changeset(assistant, attrs)
  end

  @doc """
  Returns the list of tournament_chat_topics.

  ## Examples

      iex> list_tournament_chat_topics()
      [%TournamentChatTopic{}, ...]

  """
  def list_tournament_chat_topics do
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
  Creates a tournament_chat_topic.

  ## Examples

      iex> create_tournament_chat_topic(%{field: value})
      {:ok, %TournamentChatTopic{}}

      iex> create_tournament_chat_topic(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tournament_chat_topic(attrs \\ %{}) do
    %TournamentChatTopic{}
    |> TournamentChatTopic.changeset(attrs)
    |> Repo.insert()
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
  Returns an `%Ecto.Changeset{}` for tracking tournament_chat_topic changes.

  ## Examples

      iex> change_tournament_chat_topic(tournament_chat_topic)
      %Ecto.Changeset{data: %TournamentChatTopic{}}

  """
  def change_tournament_chat_topic(%TournamentChatTopic{} = tournament_chat_topic, attrs \\ %{}) do
    TournamentChatTopic.changeset(tournament_chat_topic, attrs)
  end

  @doc """
  Returns the list of tournament_user_topic_log.

  ## Examples

      iex> list_tournament_user_topic_log()
      [%TournamentChatTopicLog{}, ...]

  """
  def list_tournament_user_topic_log do
    Repo.all(TournamentChatTopicLog)
  end

  @doc """
  Gets a single tournament_chat_topic_log.

  Raises `Ecto.NoResultsError` if the Tournament chat topic log does not exist.

  ## Examples

      iex> get_tournament_chat_topic_log!(123)
      %TournamentChatTopicLog{}

      iex> get_tournament_chat_topic_log!(456)
      ** (Ecto.NoResultsError)

  """
  def get_tournament_chat_topic_log!(id), do: Repo.get!(TournamentChatTopicLog, id)

  @doc """
  Creates a tournament_chat_topic_log.

  ## Examples

      iex> create_tournament_chat_topic_log(%{field: value})
      {:ok, %TournamentChatTopicLog{}}

      iex> create_tournament_chat_topic_log(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tournament_chat_topic_log(attrs \\ %{}) do
    %TournamentChatTopicLog{}
    |> TournamentChatTopicLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a tournament_chat_topic_log.

  ## Examples

      iex> update_tournament_chat_topic_log(tournament_chat_topic_log, %{field: new_value})
      {:ok, %TournamentChatTopicLog{}}

      iex> update_tournament_chat_topic_log(tournament_chat_topic_log, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tournament_chat_topic_log(%TournamentChatTopicLog{} = tournament_chat_topic_log, attrs) do
    tournament_chat_topic_log
    |> TournamentChatTopicLog.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a tournament_chat_topic_log.

  ## Examples

      iex> delete_tournament_chat_topic_log(tournament_chat_topic_log)
      {:ok, %TournamentChatTopicLog{}}

      iex> delete_tournament_chat_topic_log(tournament_chat_topic_log)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tournament_chat_topic_log(%TournamentChatTopicLog{} = tournament_chat_topic_log) do
    Repo.delete(tournament_chat_topic_log)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tournament_chat_topic_log changes.

  ## Examples

      iex> change_tournament_chat_topic_log(tournament_chat_topic_log)
      %Ecto.Changeset{data: %TournamentChatTopicLog{}}

  """
  def change_tournament_chat_topic_log(%TournamentChatTopicLog{} = tournament_chat_topic_log, attrs \\ %{}) do
    TournamentChatTopicLog.changeset(tournament_chat_topic_log, attrs)
  end
end

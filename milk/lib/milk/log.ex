defmodule Milk.Log do
  @moduledoc """
  The Log context.
  """

  import Ecto.Query, warn: false
  import Common.Sperm

  alias Common.Tools

  alias Milk.{
    Accounts,
    Repo,
    Tournaments
  }

  alias Milk.Log.{
    AssistantLog,
    ChatRoomLog,
    TournamentChatTopicLog,
    TeamLog,
    TeamMemberLog
  }

  alias Milk.Tournaments.{
    Entrant
  }

  @doc """
  Returns the list of chat_room_log.

  ## Examples

      iex> list_chat_room_log()
      [%ChatRoomLog{}, ...]

  """
  def list_chat_room_log do
    Repo.all(ChatRoomLog)
  end

  @doc """
  Gets a single chat_room_log.

  Raises `Ecto.NoResultsError` if the Chat room log does not exist.

  ## Examples

      iex> get_chat_room_log!(123)
      %ChatRoomLog{}

      iex> get_chat_room_log!(456)
      ** (Ecto.NoResultsError)

  """
  def get_chat_room_log!(id), do: Repo.get!(ChatRoomLog, id)

  @doc """
  Creates a chat_room_log.

  ## Examples

      iex> create_chat_room_log(%{field: value})
      {:ok, %ChatRoomLog{}}

      iex> create_chat_room_log(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_chat_room_log(attrs \\ %{}) do
    %ChatRoomLog{}
    |> ChatRoomLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a chat_room_log.

  ## Examples

      iex> update_chat_room_log(chat_room_log, %{field: new_value})
      {:ok, %ChatRoomLog{}}

      iex> update_chat_room_log(chat_room_log, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_chat_room_log(%ChatRoomLog{} = chat_room_log, attrs) do
    chat_room_log
    |> ChatRoomLog.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a chat_room_log.

  ## Examples

      iex> delete_chat_room_log(chat_room_log)
      {:ok, %ChatRoomLog{}}

      iex> delete_chat_room_log(chat_room_log)
      {:error, %Ecto.Changeset{}}

  """
  def delete_chat_room_log(%ChatRoomLog{} = chat_room_log) do
    Repo.delete(chat_room_log)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking chat_room_log changes.

  ## Examples

      iex> change_chat_room_log(chat_room_log)
      %Ecto.Changeset{data: %ChatRoomLog{}}

  """
  def change_chat_room_log(%ChatRoomLog{} = chat_room_log, attrs \\ %{}) do
    ChatRoomLog.changeset(chat_room_log, attrs)
  end

  alias Milk.Log.ChatMemberLog

  @doc """
  Returns the list of chat_member_log.

  ## Examples

      iex> list_chat_member_log()
      [%ChatMemberLog{}, ...]

  """
  def list_chat_member_log do
    Repo.all(ChatMemberLog)
  end

  @doc """
  Gets a single chat_member_log.

  Raises `Ecto.NoResultsError` if the Chat member log does not exist.

  ## Examples

      iex> get_chat_member_log!(123)
      %ChatMemberLog{}

      iex> get_chat_member_log!(456)
      ** (Ecto.NoResultsError)

  """
  def get_chat_member_log!(id), do: Repo.get!(ChatMemberLog, id)

  @doc """
  Creates a chat_member_log.

  ## Examples

      iex> create_chat_member_log(%{field: value})
      {:ok, %ChatMemberLog{}}

      iex> create_chat_member_log(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_chat_member_log(attrs \\ %{}) do
    %ChatMemberLog{}
    |> ChatMemberLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a chat_member_log.

  ## Examples

      iex> update_chat_member_log(chat_member_log, %{field: new_value})
      {:ok, %ChatMemberLog{}}

      iex> update_chat_member_log(chat_member_log, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_chat_member_log(%ChatMemberLog{} = chat_member_log, attrs) do
    chat_member_log
    |> ChatMemberLog.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a chat_member_log.

  ## Examples

      iex> delete_chat_member_log(chat_member_log)
      {:ok, %ChatMemberLog{}}

      iex> delete_chat_member_log(chat_member_log)
      {:error, %Ecto.Changeset{}}

  """
  def delete_chat_member_log(%ChatMemberLog{} = chat_member_log) do
    Repo.delete(chat_member_log)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking chat_member_log changes.

  ## Examples

      iex> change_chat_member_log(chat_member_log)
      %Ecto.Changeset{data: %ChatMemberLog{}}

  """
  def change_chat_member_log(%ChatMemberLog{} = chat_member_log, attrs \\ %{}) do
    ChatMemberLog.changeset(chat_member_log, attrs)
  end

  alias Milk.Log.ChatsLog

  @doc """
  Returns the list of chat_log.

  ## Examples

      iex> list_chat_log()
      [%ChatsLog{}, ...]

  """
  def list_chat_log do
    Repo.all(ChatsLog)
  end

  @doc """
  Gets a single chats_log.

  Raises `Ecto.NoResultsError` if the Chats log does not exist.

  ## Examples

      iex> get_chats_log!(123)
      %ChatsLog{}

      iex> get_chats_log!(456)
      ** (Ecto.NoResultsError)

  """
  def get_chats_log!(id), do: Repo.get!(ChatsLog, id)

  @doc """
  Creates a chats_log.

  ## Examples

      iex> create_chats_log(%{field: value})
      {:ok, %ChatsLog{}}

      iex> create_chats_log(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_chats_log(attrs \\ %{}) do
    %ChatsLog{}
    |> ChatsLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a chats_log.

  ## Examples

      iex> update_chats_log(chats_log, %{field: new_value})
      {:ok, %ChatsLog{}}

      iex> update_chats_log(chats_log, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_chats_log(%ChatsLog{} = chats_log, attrs) do
    chats_log
    |> ChatsLog.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a chats_log.

  ## Examples

      iex> delete_chats_log(chats_log)
      {:ok, %ChatsLog{}}

      iex> delete_chats_log(chats_log)
      {:error, %Ecto.Changeset{}}

  """
  def delete_chats_log(%ChatsLog{} = chats_log) do
    Repo.delete(chats_log)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking chats_log changes.

  ## Examples

      iex> change_chats_log(chats_log)
      %Ecto.Changeset{data: %ChatsLog{}}

  """
  def change_chats_log(%ChatsLog{} = chats_log, attrs \\ %{}) do
    ChatsLog.changeset(chats_log, attrs)
  end

  alias Milk.Log.TournamentLog

  @doc """
  Returns the list of tournament_log.

  ## Examples

      iex> list_tournament_log()
      [%Tournament{}, ...]

  """
  def list_tournament_log do
    Repo.all(TournamentLog)
  end

  @doc """
  Gets a single tournament.

  Raises `Ecto.NoResultsError` if the Tournament does not exist.
  """
  def get_tournament_log!(id), do: Repo.get(TournamentLog, id)

  @doc """
  Gets a single tournament.
  """
  def get_tournament_log(id) do
    TournamentLog
    |> where([t], t.id == ^id)
    |> Repo.one()
  end

  @doc """
  Gets a single tournament log by tournament id.
  """
  def get_tournament_log_by_tournament_id(tournament_id) do
    TournamentLog
    |> where([t], t.tournament_id == ^tournament_id)
    |> Repo.one()
  end

  @doc """
  Creates a tournament.

  ## Examples

      iex> create_tournament(%{field: value})
      {:ok, %Tournament{}}

      iex> create_tournament(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tournament_log(attrs \\ %{}) do
    %TournamentLog{}
    |> TournamentLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a tournament.

  ## Examples

      iex> update_tournament(tournament, %{field: new_value})
      {:ok, %Tournament{}}

      iex> update_tournament(tournament, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tournament_log(%TournamentLog{} = tournament, attrs) do
    tournament
    |> TournamentLog.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a tournament.

  ## Examples

      iex> delete_tournament(tournament)
      {:ok, %Tournament{}}

      iex> delete_tournament(tournament)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tournament_log(%TournamentLog{} = tournament) do
    Repo.delete(tournament)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tournament changes.

  ## Examples

      iex> change_tournament(tournament)
      %Ecto.Changeset{data: %Tournament{}}

  """
  def change_tournament_log(%TournamentLog{} = tournament, attrs \\ %{}) do
    TournamentLog.changeset(tournament, attrs)
  end

  alias Milk.Log.EntrantLog

  @doc """
  Returns the list of entrant_log.

  ## Examples

      iex> list_entrant_log()
      [%EntrantLog{}, ...]

  """
  def list_entrant_log do
    Repo.all(EntrantLog)
  end

  @doc """
  Gets a single entrant_log.

  Raises `Ecto.NoResultsError` if the Entrant log does not exist.

  ## Examples

      iex> get_entrant_log!(123)
      %EntrantLog{}

      iex> get_entrant_log!(456)
      ** (Ecto.NoResultsError)

  """
  def get_entrant_log!(id), do: Repo.get!(EntrantLog, id)

  @doc """
  Get a single entrant log by entrant id.
  """
  @spec get_entrant_log_by_entrant_id(integer()) :: EntrantLog.t() | nil
  def get_entrant_log_by_entrant_id(id) do
    EntrantLog
    |> where([e], e.entrant_id == ^id)
    |> Repo.one()
  end

  @doc """
  Get a single entrant log by user id and tournament id.
  """
  def get_entrant_log_by_user_id_and_tournament_id(user_id, tournament_id) do
    EntrantLog
    |> where([e], e.user_id == ^user_id)
    |> where([e], e.tournament_id == ^tournament_id)
    |> Repo.one()
  end

  @doc """
  Get entrant logs by tournament id.
  """
  def get_entrant_logs_by_tournament_id(tournament_id) do
    EntrantLog
    |> where([e], e.tournament_id == ^tournament_id)
    |> Repo.all()
  end

  @doc """
  Creates a entrant_log.

  ## Examples

      iex> create_entrant_log(%{field: value})
      {:ok, %EntrantLog{}}

      iex> create_entrant_log(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_entrant_log(Entrant.t() | integer() | map()) :: {:ok, EntrantLog.t()} | {:error, String.t() | nil}
  def create_entrant_log(entrant_id) when is_integer(entrant_id) do
    entrant_id
    |> Tournaments.get_entrant()
    |> __MODULE__.create_entrant_log()
  end

  def create_entrant_log(%Entrant{} = entrant) do
    entrant
    |> Map.from_struct()
    |> Map.put(:entrant_id, entrant.id)
    |> __MODULE__.create_entrant_log()
  end

  def create_entrant_log(attrs) do
    %EntrantLog{}
    |> EntrantLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a entrant_log.

  ## Examples

      iex> update_entrant_log(entrant_log, %{field: new_value})
      {:ok, %EntrantLog{}}

      iex> update_entrant_log(entrant_log, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_entrant_log(%EntrantLog{} = entrant_log, attrs) do
    entrant_log
    |> EntrantLog.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a entrant_log.

  ## Examples

      iex> delete_entrant_log(entrant_log)
      {:ok, %EntrantLog{}}

      iex> delete_entrant_log(entrant_log)
      {:error, %Ecto.Changeset{}}

  """
  def delete_entrant_log(%EntrantLog{} = entrant_log) do
    Repo.delete(entrant_log)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking entrant_log changes.

  ## Examples

      iex> change_entrant_log(entrant_log)
      %Ecto.Changeset{data: %EntrantLog{}}

  """
  def change_entrant_log(%EntrantLog{} = entrant_log, attrs \\ %{}) do
    EntrantLog.changeset(entrant_log, attrs)
  end

  @doc """
  Returns the list of assistant_log.

  ## Examples

      iex> list_assistant_log()
      [%AssistantLog{}, ...]

  """
  def list_assistant_log do
    Repo.all(AssistantLog)
  end

  @doc """
  Gets a single assistant_log.

  Raises `Ecto.NoResultsError` if the Assistant log does not exist.

  ## Examples

      iex> get_assistant_log!(123)
      %AssistantLog{}

      iex> get_assistant_log!(456)
      ** (Ecto.NoResultsError)

  """
  def get_assistant_log!(id), do: Repo.get!(AssistantLog, id)

  @doc """
  Get assistant logs.
  """
  def get_assistant_logs_by_tournament_id(tournament_id) do
    AssistantLog
    |> where([al], al.tournament_id == ^tournament_id)
    |> Repo.all()
  end

  @doc """
  Creates a assistant_log.

  ## Examples

      iex> create_assistant_log(%{field: value})
      {:ok, %AssistantLog{}}

      iex> create_assistant_log(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_assistant_log(attrs \\ %{}) do
    Enum.all?(attrs, fn attr ->
      !is_nil(attr["tournament_id"]) && !is_nil(attr["user_id"])
    end)
    |> if do
      Enum.filter(attrs, fn x ->
        !Repo.exists?(
          from al in AssistantLog,
            where: al.tournament_id == ^x["tournament_id"] and al.user_id == ^x["user_id"]
        )
      end)
      |> Enum.map(fn x ->
        %AssistantLog{}
        |> AssistantLog.changeset(x)
        |> Repo.insert()
      end)
    else
      [error: nil]
    end
  end

  @doc """
  Updates a assistant_log.

  ## Examples

      iex> update_assistant_log(assistant_log, %{field: new_value})
      {:ok, %AssistantLog{}}

      iex> update_assistant_log(assistant_log, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_assistant_log(%AssistantLog{} = assistant_log, attrs) do
    assistant_log
    |> AssistantLog.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a assistant_log.

  ## Examples

      iex> delete_assistant_log(assistant_log)
      {:ok, %AssistantLog{}}

      iex> delete_assistant_log(assistant_log)
      {:error, %Ecto.Changeset{}}

  """
  def delete_assistant_log(%AssistantLog{} = assistant_log) do
    Repo.delete(assistant_log)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking assistant_log changes.

  ## Examples

      iex> change_assistant_log(assistant_log)
      %Ecto.Changeset{data: %AssistantLog{}}

  """
  def change_assistant_log(%AssistantLog{} = assistant_log, attrs \\ %{}) do
    AssistantLog.changeset(assistant_log, attrs)
  end

  alias Milk.Log.NotificationLog

  @doc """
  Returns the list of notification_log.

  ## Examples

      iex> list_notification_log()
      [%NotificationLog{}, ...]

  """
  def list_notification_log do
    Repo.all(NotificationLog)
  end

  @doc """
  Gets a single notification_log.

  Raises `Ecto.NoResultsError` if the Notification log does not exist.

  ## Examples

      iex> get_notification_log!(123)
      %NotificationLog{}

      iex> get_notification_log!(456)
      ** (Ecto.NoResultsError)

  """
  def get_notification_log!(id), do: Repo.get!(NotificationLog, id)

  @doc """
  Creates a notification_log.

  ## Examples

      iex> create_notification_log(%{field: value})
      {:ok, %NotificationLog{}}

      iex> create_notification_log(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_notification_log(attrs \\ %{}) do
    %NotificationLog{}
    |> NotificationLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a notification_log.

  ## Examples

      iex> update_notification_log(notification_log, %{field: new_value})
      {:ok, %NotificationLog{}}

      iex> update_notification_log(notification_log, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_notification_log(%NotificationLog{} = notification_log, attrs) do
    notification_log
    |> NotificationLog.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a notification_log.

  ## Examples

      iex> delete_notification_log(notification_log)
      {:ok, %NotificationLog{}}

      iex> delete_notification_log(notification_log)
      {:error, %Ecto.Changeset{}}

  """
  def delete_notification_log(%NotificationLog{} = notification_log) do
    Repo.delete(notification_log)
  end

  @doc """
  Returns the list of tournament_chat_topic_log.

  ## Examples

      iex> list_tournament_chat_topic_log()
      [%TournamentChatTopicLog{}, ...]

  """
  def list_tournament_chat_topic_log do
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
  def update_tournament_chat_topic_log(
        %TournamentChatTopicLog{} = tournament_chat_topic_log,
        attrs
      ) do
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
  def change_tournament_chat_topic_log(
        %TournamentChatTopicLog{} = tournament_chat_topic_log,
        attrs \\ %{}
      ) do
    TournamentChatTopicLog.changeset(tournament_chat_topic_log, attrs)
  end

  @doc """
  Create team log
  """
  def create_team_log(team_id) when is_integer(team_id) do
    team_id
    |> Tournaments.load_team()
    ~> team
    |> Map.get(:team_member)
    |> Enum.each(fn member ->
      member
      |> Map.from_struct()
      |> Tools.atom_map_to_string_map()
      |> create_team_member_log()
    end)

    team
    |> Map.from_struct()
    |> Map.put(:team_id, team.id)
    |> Tools.atom_map_to_string_map()
    |> create_team_log()
  end

  def create_team_log(attrs) do
    %TeamLog{}
    |> TeamLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Get team logs
  """
  def get_team_log(id) do
    Repo.get(TeamLog, id)
  end

  @doc """
  Get team log by team id
  """
  def get_team_log_by_team_id(team_id) do
    TeamMemberLog
    |> where([t], t.team_id == ^team_id)
    |> Repo.all()
    |> Enum.map(fn team_member_log ->
      user = Accounts.get_user(team_member_log.user_id)
      Map.put(team_member_log, :user, Repo.preload(user, :auth))
    end)
    ~> team_member_logs

    TeamLog
    |> where([t], t.team_id == ^team_id)
    |> Repo.one()
    ~> team_log

    unless is_nil(team_log) do
      Map.put(team_log, :team_member, team_member_logs)
    end
  end

  @doc """
  Get team logs by tournament id
  """
  def get_team_logs_by_tournament_id(tournament_id) do
    TeamLog
    |> where([t], t.tournament_id == ^tournament_id)
    |> Repo.all()
  end

  @doc """
  Get team log by tournament id and user id.
  """
  @spec get_team_log_by_tournament_id_and_user_id(integer(), integer()) :: TeamLog.t() | nil
  def get_team_log_by_tournament_id_and_user_id(tournament_id, user_id) do
    TeamLog
    |> where([t], t.tournament_id == ^tournament_id)
    |> Repo.all()
    |> Enum.filter(fn team_log ->
      TeamMemberLog
      |> where([t], t.team_id == ^team_log.team_id and t.user_id == ^user_id)
      |> Repo.exists?()
    end)
    |> Enum.map(fn team_log ->
      TeamMemberLog
      |> where([t], t.team_id == ^team_log.team_id)
      |> Repo.all()
      ~> members

      Map.put(team_log, :team_member, members)
    end)
    |> Tools.hd_as_needed()
  end

  @doc """
  Create team member log.
  """
  def create_team_member_log(attrs \\ %{}) do
    %TeamMemberLog{}
    |> TeamMemberLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Get team member log
  """
  def get_team_member_log(id) do
    Repo.get(TeamMemberLog, id)
  end

  @doc """
  Get team member logs.
  """
  def get_team_member_logs(team_id) do
    TeamMemberLog
    |> where([tm], tm.team_id == ^team_id)
    |> Repo.all()
  end

  def load_team_member_logs(team_id) do
    team_id
    |> __MODULE__.get_team_member_logs()
    |> Enum.map(fn member ->
      user = Accounts.get_user(member.user_id)
      Map.put(member, :user, Repo.preload(user, :auth))
    end)
    |> IO.inspect()
  end
end

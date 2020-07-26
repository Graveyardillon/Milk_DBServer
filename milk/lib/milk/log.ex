defmodule Milk.Log do
  @moduledoc """
  The Log context.
  """

  import Ecto.Query, warn: false
  alias Milk.Repo

  alias Milk.Log.ChatRoomLog

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
end

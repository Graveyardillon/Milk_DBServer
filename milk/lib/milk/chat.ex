defmodule Milk.Chat do
  @moduledoc """
  The Chat context.
  """

  import Ecto.Query, warn: false
  alias Milk.Repo

  alias Milk.Chat.ChatRoom
  alias Milk.Chat.Chats
  alias Milk.Chat.ChatMember
  alias Milk.Accounts.User
  alias Milk.Accounts
  alias Milk.Log.ChatsLog
  alias Milk.Log.ChatMemberLog
  alias Milk.Log.ChatRoomLog
  alias Ecto.Multi

  @doc """
  Returns the list of chat_room.

  ## Examples

      iex> list_chat_room()
      [%ChatRoom{}, ...]

  """
  def list_chat_room do
    Repo.all(ChatRoom)
  end

  def get_all_chat(id) do
    Repo.one(from cr in ChatRoom, 
    left_join: cm in assoc(cr, :chat_member),
    left_join: c in assoc(cr, :chat),
    where: cr.id == ^id,
    preload: [chat_member: cm, chat: c])
  end

  @doc """
  Gets a single chat_room.

  Raises `Ecto.NoResultsError` if the Chat room does not exist.

  ## Examples

      iex> get_chat_room!(123)
      %ChatRoom{}

      iex> get_chat_room!(456)
      ** (Ecto.NoResultsError)

  """
  def get_chat_room(id), do: Repo.one(from cr in ChatRoom, join: c in assoc(cr, :chat), where: cr.id == ^id, preload: [chat: c])

  @doc """
  Creates a chat_room.

  ## Examples

      iex> create_chat_room(%{field: value})
      {:ok, %ChatRoom{}}

      iex> create_chat_room(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_chat_room(attrs \\ %{}) do
    %ChatRoom{}
    |> ChatRoom.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a chat_room.

  ## Examples

      iex> update_chat_room(chat_room, %{field: new_value})
      {:ok, %ChatRoom{}}

      iex> update_chat_room(chat_room, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_chat_room(%ChatRoom{} = chat_room, attrs) do
    chat_room
    |> ChatRoom.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a chat_room.

  ## Examples

      iex> delete_chat_room(chat_room)
      {:ok, %ChatRoom{}}

      iex> delete_chat_room(chat_room)
      {:error, %Ecto.Changeset{}}

  """
  def delete_chat_room(%ChatRoom{} = chat_room) do
    chat = Enum.map(chat_room.chat, fn x -> %{chat_room_id: x.chat_room_id, word: x.word, user_id: x.user_id, index: x.index, create_time: x.create_time, update_time: x.update_time} end)
    if chat, do: Repo.insert_all(ChatsLog, chat)
    IO.inspect chat
    member = Enum.map(chat_room.chat_member, fn x -> %{chat_room_id: x.chat_room_id, user_id: x.user_id, authority: x.authority, create_time: x.create_time, update_time: x.update_time} end)
    if member, do: Repo.insert_all(ChatMemberLog, member)
    ChatRoomLog.changeset(%ChatRoomLog{}, Map.from_struct(chat_room)) |> IO.inspect
    |> Repo.insert()
    Repo.delete(chat_room)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking chat_room changes.

  ## Examples

      iex> change_chat_room(chat_room)
      %Ecto.Changeset{data: %ChatRoom{}}

  """
  def change_chat_room(%ChatRoom{} = chat_room, attrs \\ %{}) do
    ChatRoom.changeset(chat_room, attrs)
  end

  alias Milk.Chat.ChatMember

  @doc """
  Returns the list of chat_member.

  ## Examples

      iex> list_chat_member()
      [%ChatMember{}, ...]

  """
  def list_chat_member(params) do
    IO.inspect params["chat_room_id"]
    Repo.all(from cm in ChatMember, 
      join: u in assoc(cm, :user), 
      join: cr in assoc(cm, :chat_room), 
      order_by: u.create_time, preload: [chat_room: cr, user: u], 
      where: cm.chat_room_id == ^params["chat_room_id"])
  end

  @doc """
  Gets a single chat_member.

  Raises `Ecto.NoResultsError` if the Chat member does not exist.

  ## Examples

      iex> get_chat_member!(123)
      %ChatMember{}

      iex> get_chat_member!(456)
      ** (Ecto.NoResultsError)

  """
  def get_chat_member!(id), do: Repo.get!(ChatMember, id)

  def get_member(chat_room_id, user_id), do: Repo.one(from cm in ChatMember, where: cm.chat_room_id == ^chat_room_id and cm.user_id == ^user_id)

  @doc """
  Creates a chat_member.

  ## Examples

      iex> create_chat_member(%{field: value})
      {:ok, %ChatMember{}}

      iex> create_chat_member(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_chat_member(attrs \\ %{}) do
    if (Repo.exists?(from u in User, join: a in assoc(u, :auth), where: u.id == ^attrs["user_id"]) 
      and Repo.exists?(from c in ChatRoom, where: c.id == ^attrs["chat_room_id"])) do
      %ChatMember{user_id: attrs["user_id"], chat_room_id: attrs["chat_room_id"]}
      |> ChatMember.changeset(attrs)
      |> Repo.insert()
    else
      {:error, nil}
    end
  end

  @doc """
  Updates a chat_member.

  ## Examples

      iex> update_chat_member(chat_member, %{field: new_value})
      {:ok, %ChatMember{}}

      iex> update_chat_member(chat_member, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_chat_member(%ChatMember{} = chat_member, attrs) do
    chat_member
    |> ChatMember.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a chat_member.

  ## Examples

      iex> delete_chat_member(chat_member)
      {:ok, %ChatMember{}}

      iex> delete_chat_member(chat_member)
      {:error, %Ecto.Changeset{}}

  """
  def delete_chat_member(%ChatMember{} = chat_member) do
    ChatMemberLog.changeset(%ChatMemberLog{}, Map.from_struct(chat_member))
    |> Repo.insert()
    Repo.delete(chat_member)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking chat_member changes.

  ## Examples

      iex> change_chat_member(chat_member)
      %Ecto.Changeset{data: %ChatMember{}}

  """
  def change_chat_member(%ChatMember{} = chat_member, attrs \\ %{}) do
    ChatMember.changeset(chat_member, attrs)
  end

  alias Milk.Chat.Chats

  @doc """
  Returns the list of chat.

  ## Examples

      iex> list_chat()
      [%Chats{}, ...]

  """
  def list_chat(params) do
    Repo.all(from c in Chats, where: c.chat_room_id == ^params["chat_room_id"] and c.index < ^params["max"] and c.index > ^params["min"])
  end

  @doc """
  Gets a single chats.

  Raises `Ecto.NoResultsError` if the Chats does not exist.

  ## Examples

      iex> get_chats!(123)
      %Chats{}

      iex> get_chats!(456)
      ** (Ecto.NoResultsError)

  """
  def get_chats!(id), do: Repo.get!(Chats, id)

  def get_chat(chat_room_id, index), do: Repo.one(from c in Chats, where: c.chat_room_id == ^chat_room_id and c.index == ^index)

  def get_latest_chat(id), do: Repo.all(from c in Chats, where: c.chat_room_id == ^id, order_by: [desc: c.index], limit: 20)

  def sync(date, id) do
    Repo.all(from cr in ChatRoom, left_join: cm in assoc(cr, :chat_member), where: cm.user_id == ^id and cr.update_time >= ^date)
    |> IO.inspect
  end
  @doc """
  Creates a chats.

  ## Examples

      iex> create_chats(%{field: value})
      {:ok, %Chats{}}

      iex> create_chats(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_chats(attrs \\ %{}) do
    if (Repo.exists?(from cm in ChatMember, where: cm.user_id == ^attrs["user_id"] and cm.chat_room_id == ^attrs["chat_room_id"])) |> IO.inspect do
      # cr = Repo.get(ChatRoom, attrs["chat_room_id"])
      # if cr do
      #   {:ok, chat} = %Chats{user_id: attrs["user_id"], chat_room_id: attrs["chat_room_id"], index: cr.count + 1}
      #   |> Chats.changeset(attrs)
      #   |> Repo.insert()
      #   |> IO.inspect
      case Multi.new() 
      |> Multi.run(:chat_room, fn repo, _ -> 
        {:ok, repo.get(ChatRoom, attrs["chat_room_id"])}
      end)
      |> Multi.insert(:chat, fn %{chat_room: chat_room} ->
        %Chats{user_id: attrs["user_id"], chat_room_id: attrs["chat_room_id"], index: chat_room.count + 1}
        |> Chats.changeset(attrs)
      end)
      |> Repo.transaction() do

      {:ok, chat} ->
        chat.chat_room
        |> ChatRoom.changeset(%{last_chat: chat.chat.word, count: chat.chat.index})
        |> Repo.update
        {:ok, chat.chat}
      _ ->
        {:error, nil}
      end
    else
      {:error, nil}
    end
  end

  @doc """
  Updates a chats.

  ## Examples

      iex> update_chats(chats, %{field: new_value})
      {:ok, %Chats{}}

      iex> update_chats(chats, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_chats(%Chats{} = chats, attrs) do
    chats
    |> Chats.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a chats.

  ## Examples

      iex> delete_chats(chats)
      {:ok, %Chats{}}

      iex> delete_chats(chats)
      {:error, %Ecto.Changeset{}}

  """
  def delete_chats(%Chats{} = chats) do
    ChatsLog.changeset(%ChatsLog{}, Map.from_struct(chats))
    |> Repo.insert()
    Repo.delete(chats)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking chats changes.

  ## Examples

      iex> change_chats(chats)
      %Ecto.Changeset{data: %Chats{}}

  """
  def change_chats(%Chats{} = chats, attrs \\ %{}) do
    Chats.changeset(chats, attrs)
  end
end

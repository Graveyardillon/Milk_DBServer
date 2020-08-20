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
  def get_chat_room(id), do: Repo.one(from cr in ChatRoom, where: cr.id == ^id)

  @doc """
  Creates a chat_room.

  ## Examples

      iex> create_chat_room(%{field: value})
      {:ok, %ChatRoom{}}

      iex> create_chat_room(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_chat_room(attrs \\ %{}) do
    case %ChatRoom{}
    |> ChatRoom.changeset(attrs)
    |> Repo.insert() do
    {:ok, chat} ->
      {:ok, chat}
    {:error, error} ->
      {:error, error.errors}
    _ ->
      {:error, nil}
    end
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
    |> ChatRoom.changeset_update(
      Map.put(attrs, "update_time", DateTime.utc_now)
    )
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
    member = Enum.map(chat_room.chat_member, fn x -> %{chat_room_id: x.chat_room_id, user_id: x.user_id, authority: x.authority, create_time: x.create_time, update_time: x.update_time} end)
    if member, do: Repo.insert_all(ChatMemberLog, member)
    ChatRoomLog.changeset(%ChatRoomLog{}, Map.from_struct(chat_room))
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
  def get_chat_member!(id), do: Repo.get(ChatMember, id)

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
    if (Repo.exists?(from u in User, where: u.id == ^attrs["user_id"])) do
      chat_room = Repo.one(from c in ChatRoom, where: c.id == ^attrs["chat_room_id"])
      # if chat_room do
      #   case %ChatMember{user_id: attrs["user_id"], chat_room_id: attrs["chat_room_id"]}
      #   |> ChatMember.changeset(attrs)
      #   |> Repo.insert() do
      #   {:ok, chat_member} ->
      #     Repo.update()
      #     {:ok, chat_member}
      #   {:error, error} ->
      #     {:error, error.errors}
      #   _ ->
      #     {:error, nil}
      #   end
      # else
      #   {:error, nil}
      # end
      case Multi.new() 
      |> Multi.run(:chat_room, fn repo, _ -> 
        {:ok, repo.get(ChatRoom, attrs["chat_room_id"])}
      end)
      |> Multi.insert(:chat_member, fn %{chat_room: chat_room} ->
        ChatMember.changeset(%ChatMember{user_id: attrs["user_id"], chat_room_id: attrs["chat_room_id"]}, attrs)
      end)
      |> Multi.update(:update, fn %{chat_room: chat_room} ->
        ChatRoom.changeset_update(chat_room, %{member_count: chat_room.member_count + 1})
      end)
      |> Repo.transaction() do

      {:ok, chat_member} ->
        {:ok, chat_member.chat_member}
      {:error, _, error, data} -> 
        {:error, error.errors}
      _ ->
        {:error, nil}
      end
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
    case chat_member
    |> ChatMember.changeset(attrs)
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
  def get_chats!(id), do: Repo.get(Chats, id)

  def get_chat(chat_room_id, index), do: Repo.one(from c in Chats, where: c.chat_room_id == ^chat_room_id and c.index == ^index)

  def get_latest_chat(id), do: Repo.all(from c in Chats, where: c.chat_room_id == ^id, order_by: [desc: c.index], limit: 20)

  def sync(date, id) do
    Repo.all(from cr in ChatRoom, left_join: cm in assoc(cr, :chat_member), where: cm.user_id == ^id and cr.update_time >= ^date)
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
    if (Repo.exists?(from cm in ChatMember, where: cm.user_id == ^attrs["user_id"] and cm.chat_room_id == ^attrs["chat_room_id"])) do
      
      case Multi.new() 
      |> Multi.run(:chat_room, fn repo, _ -> 
        {:ok, repo.get(ChatRoom, attrs["chat_room_id"])}
      end)
      |> Multi.insert(:chat, fn %{chat_room: chat_room} ->
        %Chats{user_id: attrs["user_id"], chat_room_id: attrs["chat_room_id"], index: chat_room.count + 1, update_time: attrs["datetime"], create_time: attrs["datetime"]}
        |> Chats.changeset(attrs)
      end)
      |> Repo.transaction() do

      {:ok, chat} ->
        chat.chat_room
        |> IO.inspect
        |> ChatRoom.changeset_update(%{last_chat: chat.chat.word, count: chat.chat.index, update_time: attrs["datetime"]})
        |> IO.inspect
        |> Repo.update
        {:ok, chat.chat}
      {:error, _, error, data} -> 
        {:error, error.errors}
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
    |> Chats.changeset(
      Map.put(attrs, "update_time", attrs["datetime"])
      )
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

  def dialogue(attrs) do
    if (Repo.exists?(from u in User, where: u.id == ^attrs["user_id"]) 
      and Repo.exists?(from u in User, where: u.id == ^attrs["partner_id"])) do

    cr = Repo.one(from cr in ChatRoom,join: c1 in ChatMember, join: c2 in ChatMember, where: cr.member_count == 2 
      and cr.id == c1.chat_room_id 
      and c1.user_id == ^attrs["user_id"] 
      and c2.user_id == ^attrs["partner_id"] 
      and c1.chat_room_id == c2.chat_room_id
      )
    if(cr) do
      attrs
      |> Map.put("chat_room_id", cr.id)
      |> create_chats
    else
      {:ok, chat_room} = %ChatRoom{name: "%user%", member_count: 2}
      |> Repo.insert() |> IO.inspect
    
      %ChatMember{user_id: attrs["user_id"], chat_room_id: chat_room.id, authority: 0}
      |> Repo.insert()
      %ChatMember{user_id: attrs["partner_id"], chat_room_id: chat_room.id, authority: 0}
      |> Repo.insert()
    
      attrs
      |> Map.put("chat_room_id", chat_room.id)
      |> create_chats
      |> IO.inspect
    end
    end
  end
end

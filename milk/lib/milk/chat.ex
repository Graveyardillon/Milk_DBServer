defmodule Milk.Chat do
  @moduledoc """
  The Chat context.
  """

  import Ecto.Query, warn: false
  alias Milk.Repo

  alias Milk.Accounts
  alias Milk.Chat.ChatRoom
  alias Milk.Chat.Chats
  alias Milk.Chat.ChatMember
  alias Milk.Accounts.User
  # alias Milk.Accounts
  alias Milk.Tournaments.TournamentChatTopic
  alias Milk.Log.ChatsLog
  alias Milk.Log.ChatMemberLog
  alias Milk.Log.ChatRoomLog
  alias Ecto.Multi

  require Logger

  @doc """
  Returns the list of chat_room.

  ## Examples

      iex> list_chat_room()
      [%ChatRoom{}, ...]

  """
  def list_chat_room do
    Repo.all(from cr in ChatRoom,
    left_join: c in assoc(cr, :chat),
    preload: [:chat])
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
  def get_chat_room(id), do: Repo.one(from cr in ChatRoom, where: cr.id == ^id, preload: [:chat])

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
    chat =
      if is_list(chat_room.chat) do
        Enum.map(
          chat_room.chat,
          fn x ->
            %{chat_room_id: x.chat_room_id, word: x.word, user_id: x.user_id, index: x.index, create_time: x.create_time, update_time: x.update_time} 
        end)
      else
        nil
      end
    if chat, do: Repo.insert_all(ChatsLog, chat)
    member =
      if is_list(chat_room.chat_member) do
        Enum.map(chat_room.chat_member, fn x ->
          %{chat_room_id: x.chat_room_id, user_id: x.user_id, authority: x.authority, create_time: x.create_time, update_time: x.update_time} end
        )
      else
        nil
      end

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

  @doc """
  Get ChatRooms by tournament id
  """
  def get_chat_rooms_by_tournament_id(tournament_id) do
    TournamentChatTopic
    |> where([t], t.tournament_id in ^[tournament_id])
    |> Repo.all()
    |> Enum.map(fn topic ->
      get_chat_room(topic.chat_room_id)
    end)
  end

  @doc """
  Get a ChatRoom by chat member id
  """
  def get_chat_room_by_chat_member_id(chat_member_id) do
    ChatRoom
    |> where([cr], cr.id == ^chat_member_id)
    |> Repo.one()
  end

  @doc """
  Get ChatRooms by user id
  """
  def get_chat_rooms_by_user_id(user_id) do
    ChatMember
    |> where([cm], cm.user_id == ^user_id)
    |> Repo.all()
    |> Enum.map(fn member -> 
      ChatRoom
      |> where([cr], cr.id == ^member.chat_room_id)
      |> Repo.one()
    end)
  end

  def get_private_chat_room(my_id, partner_id) do
    my_id
    |> get_chat_rooms_by_user_id()
    |> Enum.filter(fn room -> 
      room.is_private
    end)
    |> Enum.map(fn room -> 
      room.id
      |> get_chat_members_of_room()
      |> Enum.filter(fn member -> 
        member.user_id == partner_id
      end)
    end)
    |> Enum.filter(fn list -> 
      list != []
    end)
    |> Enum.map(fn member ->
      m = hd(member)
      ChatRoom
      |> where([cr], cr.id == ^m.chat_room_id)
      |> Repo.one()
    end)
    |> hd()
    |> IO.inspect
  end

  def get_private_chat_rooms(user_id) do
    user_id
    |> get_chat_rooms_by_user_id()
    |> Enum.filter(fn room -> 
      room.is_private
    end)
  end

  def get_user_in_private_room(room_id, user_id) do
    room_id
    |> get_chat_members_of_room()
    |> Enum.filter(fn member -> 
      user_id != member.user_id
    end)
    |> Enum.map(fn member -> 
      Accounts.get_user(member.user_id)
    end)
    |> hd()
  end

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
  Gets all chatmember data by user_id.
  """
  def get_chat_member_by_user_id(user_id) do
    ChatMember
    |> where([cm], cm.user_id == ^user_id)
    |> Repo.all()
  end

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
      #chat_room = Repo.one(from c in ChatRoom, where: c.id == ^attrs["chat_room_id"])
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
      |> Multi.insert(:chat_member, fn %{chat_room: _chat_room} ->
        %ChatMember{user_id: attrs["user_id"], chat_room_id: attrs["chat_room_id"]}
        |> ChatMember.changeset(attrs)
      end)
      |> Multi.update(:update, fn %{chat_room: chat_room} ->
        ChatRoom.changeset(chat_room, %{member_count: chat_room.member_count + 1})
      end)
      |> Repo.transaction() do

        {:ok, chat_member} ->
          {:ok, chat_member.chat_member}
        {:error, _, error, _data} -> 
          {:error, error.errors}
        _ ->
          {:error, nil}
      end
    else
      Logger.error("User does not exist")
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

    chat_room = Repo.get(ChatRoom, chat_member.chat_room_id)
    ChatRoom.changeset(chat_room, %{member_count: chat_room.member_count - 1})
    |> Repo.update()
    Repo.delete(chat_member)
  end

  @doc """
  Get chat member list of chat room.
  """
  def get_chat_members_of_room(chat_room_id) do
    ChatMember
    |> where([cm], cm.chat_room_id == ^chat_room_id)
    |> Repo.all()
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
    Repo.all(from c in Chats, where: c.chat_room_id == ^params.chat_room_id and c.index < ^params.max and c.index > ^params.min)
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
  def get_chats!(id) do
    Repo.get!(Chats, id)
  end

  def get_chat(chat_room_id, index), do: Repo.one(from c in Chats, where: c.chat_room_id == ^chat_room_id and c.index == ^index)

  def get_latest_chat(id), do: Repo.all(from c in Chats, where: c.chat_room_id == ^id, order_by: [desc: c.index], limit: 20)

  def get_all_chat_by_room_id(room_id) do
    Chats
    |> where([c], c.chat_room_id == ^room_id)
    |> Repo.all()
  end

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
        %Chats{user_id: attrs["user_id"], chat_room_id: attrs["chat_room_id"], index: chat_room.count + 1}
        |> Chats.changeset(attrs)
      end)
      |> Repo.transaction() do

        {:ok, chat} ->
          chat.chat_room
          |> ChatRoom.changeset_update(%{last_chat: chat.chat.word, count: chat.chat.index, update_time: attrs["datetime"]})
          |> Repo.update

          {:ok, chat.chat}
        {:error, _, error, _data} -> {:error, error.errors}
        _ -> {:error, nil}
      end
    else
      Logger.error("Chat Member does not exist")
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

  # 個人チャット用の関数
  def dialogue(attrs = %{"user_id" => user_id, "partner_id" => partner_id, "word" => _word, "datetime" => _datetime}) do
    if Repo.exists?(from u in User, where: u.id == ^user_id) 
      and Repo.exists?(from u in User, where: u.id == ^partner_id) do

      cr = Repo.one(from cr in ChatRoom, join: c1 in ChatMember, join: c2 in ChatMember, where: cr.member_count == 2 
        and cr.id == c1.chat_room_id 
        and c1.user_id == ^user_id
        and c2.user_id == ^partner_id
        and c1.chat_room_id == c2.chat_room_id
        and cr.name == "%user%"
      )
      
      if cr do
        attrs
        |> Map.put("chat_room_id", cr.id)
        |> create_chats()
      else
        {:ok, chat_room} = %ChatRoom{name: "%user%", member_count: 2, is_private: true}
        |> Repo.insert() 
      
        %ChatMember{user_id: user_id, chat_room_id: chat_room.id, authority: 0}
        |> Repo.insert()
        %ChatMember{user_id: partner_id, chat_room_id: chat_room.id, authority: 0}
        |> Repo.insert()
      
        attrs
        |> Map.put("chat_room_id", chat_room.id)
        |> create_chats()
      end
    end
  end

  # グループチャット用の関数
  # TODO: チャットメンバーのユーザーのidをすべて返すようにする
  def dialogue(attrs = %{"user_id" => user_id, "chat_room_id" => chat_room_id, "word" => _word, "datetime" => _datetime}) do
    if Repo.exists?(from u in User, where: u.id == ^user_id)
      and Repo.exists?(from cr in ChatRoom, where: cr.id == ^chat_room_id) do
      
      _ = Repo.one(from cr in ChatRoom, where: cr.id == ^chat_room_id)

      attrs
      |> create_chats()
    end
  end

  # user_idに関連するチャットを全て取り出す
  def sync(user_id) do
    user_id
    |> get_chat_member_by_user_id()
    |> Enum.map(fn member ->
      get_chat_room_by_chat_member_id(member.id)
    end)
    |> Enum.filter(fn room ->
      room != nil
    end)
    |> Enum.map(fn room ->
      %{
        "room_id" => room.id,
        "data" => get_all_chat_by_room_id(room.id)
      }
    end)
  end
end

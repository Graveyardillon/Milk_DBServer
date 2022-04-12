defmodule Milk.Chat do
  @moduledoc """
  The Chat context.
  """

  import Ecto.Query, warn: false

  alias Common.Tools
  alias Ecto.Multi

  alias Milk.{
    Accounts,
    Notif,
    Tournaments
  }

  alias Milk.Accounts.User

  alias Milk.Chat.{
    ChatRoom,
    Chats,
    ChatMember
  }

  alias Milk.Log.{
    ChatsLog,
    ChatMemberLog,
    ChatRoomLog
  }

  alias Milk.Repo

  alias Milk.Tournaments.{
    Tournament,
    TournamentChatTopic
  }

  require Logger

  def get_chat_room(id) do
    Repo.one(
      from cr in ChatRoom,
        left_join: cm in assoc(cr, :chat_member),
        left_join: c in assoc(cr, :chat),
        where: cr.id == ^id,
        preload: [chat_member: cm, chat: c]
    )
  end

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
    |> case do
      {:ok, chat}     -> {:ok, chat}
      {:error, error} -> {:error, error.errors}
      _               -> {:error, nil}
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
          &(%{
            chat_room_id: &1.chat_room_id,
            word: &1.word,
            user_id: &1.user_id,
            index: &1.index,
            create_time: &1.create_time,
            update_time: &1.update_time
          })
        )
      else
        nil
      end

    if chat, do: Repo.insert_all(ChatsLog, chat)

    member =
      if is_list(chat_room.chat_member) do
        Enum.map(
          chat_room.chat_member,
          &%{
            chat_room_id: &1.chat_room_id,
            user_id: &1.user_id,
            authority: &1.authority,
            create_time: &1.create_time,
            update_time: &1.update_time
          }
        )
      else
        nil
      end

    if member, do: Repo.insert_all(ChatMemberLog, member)

    %ChatRoomLog{}
    |> ChatRoomLog.changeset(Map.from_struct(chat_room))
    |> Repo.insert()

    Repo.delete(chat_room)
  end

  @doc """
  Get ChatRooms by tournament id
  """
  def get_chat_rooms_by_tournament_id(tournament_id) do
    TournamentChatTopic
    |> where([t], t.tournament_id in ^[tournament_id])
    |> Repo.all()
    |> Enum.map(&get_chat_room(&1.chat_room_id))
  end

  @doc """
  Get a ChatRoom by chat member
  """
  def get_chat_room_by_chat_member(chat_member) do
    ChatRoom
    |> where([cr], cr.id == ^chat_member.chat_room_id)
    |> Repo.one()
  end

  @doc """
  Get ChatRooms by user id.
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
    |> Enum.filter(&(&1.is_private))
    |> Enum.map(fn room ->
      room.id
      |> get_chat_members_of_room()
      |> Enum.filter(&(&1.user_id == partner_id))
    end)
    |> Enum.reject(&Enum.empty?(&1))
    |> Enum.map(fn members ->
      member = hd(members)

      ChatRoom
      |> where([cr], cr.id == ^member.chat_room_id)
      |> Repo.one()
    end)
    |> case do
      []    -> {:error, :notfound}
      rooms -> {:ok, hd(rooms)}
    end
  end

  def get_private_chat_rooms(user_id) do
    user_id
    |> get_chat_rooms_by_user_id()
    |> Enum.filter(&(&1.is_private))
  end

  def get_user_in_private_room(room_id, user_id) do
    room_id
    |> get_chat_members_of_room()
    |> Enum.reject(&(&1.user_id == user_id))
    |> Enum.map(&Accounts.load_user(&1.user_id))
    |> hd()
  end

  def get_member(chat_room_id, user_id) do
    ChatMember
    |> where([cm], cm.chat_room_id == ^chat_room_id)
    |> where([cm], cm.user_id == ^user_id)
    |> Repo.one()
  end

  defp get_chat_member_by_user_id(user_id) do
    ChatMember
    |> where([cm], cm.user_id == ^user_id)
    |> Repo.all()
  end

  @doc """
  Get chat members by tournament id.
  It can fetch members who are in the already-created chat rooms.
  """
  def get_uniq_chat_members_by_tournament_id(tournament_id) do
    ChatMember
    |> join(:inner, [cm], cr in ChatRoom, on: cm.chat_room_id == cr.id)
    |> join(:inner, [cm, cr], tct in TournamentChatTopic, on: cr.id == tct.chat_room_id)
    |> join(:inner, [cm, cr, tct], t in Tournament, on: t.id == tct.tournament_id)
    |> where([cm, cr, tct, t], t.id == ^tournament_id)
    |> Repo.all()
    |> Enum.uniq_by(&(&1.user_id))
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
    User
    |> where([u], u.id == ^attrs["user_id"])
    |> Repo.exists?()
    |> if do
      do_create_chat_member(attrs)
    else
      {:error, "User does not exist"}
    end
  end

  defp do_create_chat_member(attrs) do
    Multi.new()
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
    |> Repo.transaction()
    |> case do
      {:ok, chat_member}        -> {:ok, chat_member.chat_member}
      {:error, _, error, _data} -> {:error, error.errors}
      _                         -> {:error, nil}
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
  def delete_chat_member(chat_room_id, user_id) do
    get_member(chat_room_id, user_id)
    |> case do
      nil ->
        {:error, nil}

      chat_member ->
        ChatMemberLog.changeset(%ChatMemberLog{}, Map.from_struct(chat_member))
        |> Repo.insert()

        chat_room = Repo.get(ChatRoom, chat_member.chat_room_id)

        ChatRoom.changeset(chat_room, %{member_count: chat_room.member_count - 1})
        |> Repo.update()

        Repo.delete(chat_member)
    end
  end

  @doc """
  Get chat member list of chat room.
  """
  def get_chat_members_of_room(chat_room_id) do
    ChatMember
    |> where([cm], cm.chat_room_id == ^chat_room_id)
    |> Repo.all()
  end

  alias Milk.Chat.Chats

  @doc """
  Returns the list of chat.

  ## Examples

      iex> list_chat()
      [%Chats{}, ...]

  """
  def list_chat(params) do
    Repo.all(
      from c in Chats,
        where:
          c.chat_room_id == ^params.chat_room_id and c.index < ^params.max and
            c.index > ^params.min
    )
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

  def get_chat(chat_room_id, index),
    do: Repo.one(from c in Chats, where: c.chat_room_id == ^chat_room_id and c.index == ^index)

  def get_latest_chat(id),
    do: Repo.all(from c in Chats, where: c.chat_room_id == ^id, order_by: [desc: c.index], limit: 20)

  @doc """
  Get all chat by room id.
  """
  def get_all_chat_by_room_id(room_id) do
    Chats
    |> where([c], c.chat_room_id == ^room_id)
    |> Repo.all()
  end

  @doc """
  Get all chat including logs by room id.
  """
  def get_all_chat_by_room_id_including_log(room_id) do
    chats =
      Chats
      |> where([c], c.chat_room_id == ^room_id)
      |> Repo.all()

    chat_logs =
      ChatsLog
      |> where([c], c.chat_room_id == ^room_id)
      |> Repo.all()

    chats ++ chat_logs
  end

  @doc """
  Synchronize chat.
  """
  def sync(date, id) do
    Repo.all(
      from cr in ChatRoom,
        left_join: cm in assoc(cr, :chat_member),
        where: cm.user_id == ^id and cr.update_time >= ^date
    )
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
    can_create? =
      !Tools.is_all_map_elements_nil?(attrs)
      |> Kernel.and(
        Repo.exists?(
          from cm in ChatMember,
            where:
              cm.user_id == ^attrs["user_id"] and
                cm.chat_room_id == ^attrs["chat_room_id"]
        )
      )

    if can_create? do
      Multi.new()
      |> Multi.run(:chat_room, fn repo, _ ->
        {:ok, repo.get(ChatRoom, attrs["chat_room_id"])}
      end)
      |> Multi.insert(:chat, fn %{chat_room: chat_room} ->
        %Chats{
          user_id: attrs["user_id"],
          chat_room_id: attrs["chat_room_id"],
          index: chat_room.count + 1
        }
        |> Chats.changeset(attrs)
      end)
      |> Repo.transaction()
      |> case do
        {:ok, chat} ->
          chat.chat_room
          |> ChatRoom.changeset_update(%{last_chat: chat.chat.word, count: chat.chat.index})
          |> Repo.update()

          {:ok, chat.chat}

        {:error, _, error, _data} ->
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

  # 個人チャット用の関数
  # TODO: 通知処理
  def dialogue(%{"user_id" => user_id, "partner_id" => partner_id, "word" => word} = attrs) do
    user_id = Tools.to_integer_as_needed(user_id)
    partner_id = Tools.to_integer_as_needed(partner_id)

    if Repo.exists?(from u in User, where: u.id == ^user_id) and
         Repo.exists?(from u in User, where: u.id == ^partner_id) do
      cr =
        Repo.one(
          from cr in ChatRoom,
            join: c1 in ChatMember,
            join: c2 in ChatMember,
            where:
              cr.member_count == 2 and
                cr.id == c1.chat_room_id and
                c1.user_id == ^user_id and
                c2.user_id == ^partner_id and
                c1.chat_room_id == c2.chat_room_id and
                cr.name == "%user%"
        )

      if cr do
        attrs
        |> Map.put("chat_room_id", cr.id)
        |> Map.put("word", word)
        |> create_chats()
      else
        {:ok, chat_room} =
          %ChatRoom{name: "%user%", member_count: 2, is_private: true}
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
  # TODO: リファクタリング
  def dialogue(%{"user_id" => user_id, "chat_room_id" => chat_room_id, "word" => message}) do
    if Repo.exists?(from u in User, where: u.id == ^user_id) and
         Repo.exists?(from cr in ChatRoom, where: cr.id == ^chat_room_id) do
      _ = Repo.one(from cr in ChatRoom, where: cr.id == ^chat_room_id)

      # 通知
      user = Accounts.get_user(user_id)

      chat_room_id
      |> get_chat_members_of_room()
      |> Enum.map(fn member ->
        Accounts.get_devices_by_user_id(member.user_id)
      end)
      |> List.flatten()
      |> Enum.each(fn device ->
        unless device.user_id == user_id do
          tournament = Tournaments.get_tournament_by_room_id(chat_room_id)

          %{
            "title" => "大会チャットに新着があります",
            "body_text" => message,
            "process_id" => "RECEIVED_TOURNAMENT_CHAT",
            "user_id" => device.user_id,
            "data" =>
              Jason.encode!(%{
                tournament_id: tournament.id,
                chat_room_id: chat_room_id
              })
          }
          |> Notif.create_notification()

          title = "#{user.name} (in #{tournament.name})"

          %Maps.PushIos{
            user_id: device.user_id,
            device_token: device.token,
            process_id: "RECEIVED_TOURNAMENT_CHAT",
            title: title,
            message: message
          }
          |> Notif.push_ios()

          # Notif.push_ios_with_badge(attrs["word"], title, device.user_id, device.token)
        end
      end)

      %{"user_id" => user_id, "chat_room_id" => chat_room_id, "word" => message}
      |> create_chats()
    end
  end

  def dialogue(user_id, chat_room_id, message) do
    dialogue(%{"user_id" => user_id, "chat_room_id" => chat_room_id, "word" => message})
  end

  # user_idに関連するチャットを全て取り出す
  def sync(user_id) do
    user_id
    |> get_chat_member_by_user_id()
    |> Enum.map(fn member ->
      get_chat_room_by_chat_member(member)
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

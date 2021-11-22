defmodule Milk.ChatTest do
  use Milk.DataCase

  use Common.Fixtures

  alias Milk.Chat
  alias Milk.Accounts

  alias Milk.Chat.{
    ChatRoom,
    Chats
  }

  alias Milk.Accounts.{
    Auth,
    User
  }

  @valid_attrs %{count: 42, last_chat: "some last_chat", name: "some name"}
  @room_attrs %{count: 42, last_chat: "some last_chat", name: "some name"}
  @user_attrs %{
    "icon_path" => "some icon_path",
    "language" => "some language",
    "name" => "some name",
    "notification_number" => 42,
    "point" => 42,
    "email" => "some email",
    "logout_fl" => true,
    "password" => "S1ome password"
  }
  @member_attrs %{"authority" => 42}

  def create_chat_member(_) do
    {:ok, user} = Accounts.create_user(@user_attrs)
    {:ok, chat_room} = Chat.create_chat_room(@room_attrs)

    {:ok, chat_member} =
      %{
        "authority" => 42,
        "chat_room_id" => chat_room.id,
        "user_id" => user.id
      }
      |> Chat.create_chat_member()

    result =
      chat_member
      |> Map.put(:chat_room_id, chat_room.id)
      |> Map.put(:user_id, user.id)

    %{chat_member: result}
  end

  def create_chat_room(_) do
    {:ok, chat_room} = Chat.create_chat_room(@valid_attrs)
    %{chat_room: Chat.get_chat_room(chat_room.id)}
  end

  def create_private_chat_room(_) do
    {:ok, user1} = Accounts.create_user(%{@user_attrs | "name" => "mgrke", "email" => "mgrke@mfedsawif.com"})

    {:ok, user2} = Accounts.create_user(%{@user_attrs | "name" => "mgrfewke", "email" => "mgrke@mfewif.com"})

    Chat.dialogue(%{"user_id" => user1.id, "partner_id" => user2.id, "word" => "fneijk"})
    {:ok, priv_chat_room} = Chat.get_private_chat_room(user1.id, user2.id)
    %{private_chat_room: priv_chat_room, user_id: user1.id, partner_id: user2.id}
  end

  def create_chat(_) do
    {:ok, user} = Accounts.create_user(@user_attrs)
    {:ok, chat_room} = Chat.create_chat_room(@room_attrs)

    {:ok, _chat_member} =
      @member_attrs
      |> Map.put("chat_room_id", chat_room.id)
      |> Map.put("user_id", user.id)
      |> Chat.create_chat_member()

    {:ok, chats} =
      %{}
      |> Enum.into(%{"word" => "some word"})
      |> Map.put("user_id", user.id)
      |> Map.put("chat_room_id", chat_room.id)
      |> Chat.create_chats()

    %{
      chat: Chat.get_chat(chat_room.id, chats.index),
      user_id: user.id,
      chat_room_id: chat_room.id
    }
  end

  describe "chat_room" do
    @update_attrs %{count: 43, last_chat: "some updated last_chat", name: "some updated name"}
    @invalid_attrs %{count: nil, last_chat: nil, name: "aa"}

    setup [:create_chat_room]
    setup [:create_chat_member]
    setup [:create_private_chat_room]
    # チャンネル取得テスト
    test "get_chat_room/1 returns the chat_room with given id", %{chat_room: chat_room} do
      assert Chat.get_chat_room(chat_room.id) == chat_room
    end

    test "get_chat_room_by_chat_member/1 returns the chat_room with given id", %{
      chat_member: chat_member
    } do
      assert Chat.get_chat_room_by_chat_member(chat_member)
    end

    test "get_chat_rooms_by_user_id/1 returns the chat_room with given id", %{
      chat_member: chat_member
    } do
      assert Chat.get_chat_rooms_by_user_id(chat_member.user_id)
    end

    test "get_private_chat_room/2 returns the private chat room", %{
      user_id: user_id,
      partner_id: partner_id
    } do
      assert Chat.get_private_chat_room(user_id, partner_id)
    end

    test "get_private_chat_rooms/1 returns the private chat room", %{user_id: user_id} do
      assert Chat.get_private_chat_rooms(user_id)
    end

    test "get_user_in_private_room/1 returns the private chat room", %{
      private_chat_room: private_chat_room,
      user_id: user_id
    } do
      assert %User{auth: %Auth{}} = Chat.get_user_in_private_room(private_chat_room.id, user_id)
    end

    test "create_chat_room/1 with valid data creates a chat_room" do
      assert {:ok, %ChatRoom{} = chat_room} = Chat.create_chat_room(@valid_attrs)
      assert chat_room.count == 42
      assert chat_room.last_chat == "some last_chat"
      assert chat_room.name == "some name"
    end

    test "create_chat_room/1 with invalid data returns error changeset" do
      assert {:error, _} = Chat.create_chat_room(@invalid_attrs)
    end

    test "update_chat_room/2 with valid data updates the chat_room", %{chat_room: chat_room} do
      assert {:ok, %ChatRoom{} = chat_room} = Chat.update_chat_room(chat_room, @update_attrs)
      assert chat_room.count == 43
      assert chat_room.last_chat == "some updated last_chat"
      assert chat_room.name == "some updated name"
    end

    test "update_chat_room/2 with invalid data returns error changeset", %{chat_room: chat_room} do
      assert {:error, %Ecto.Changeset{}} = Chat.update_chat_room(chat_room, @invalid_attrs)
      assert chat_room == Chat.get_chat_room(chat_room.id)
    end

    test "delete_chat_room/1 deletes the chat_room", %{chat_room: chat_room} do
      assert is_list(chat_room.chat)
      assert {:ok, %ChatRoom{}} = Chat.delete_chat_room(chat_room)
      assert !Chat.get_chat_room(chat_room.id)
    end

    test "dialogue/1 returns chat", %{user_id: user_id, partner_id: partner_id} do
      assert {:ok, %Chats{}} =
               Chat.dialogue(%{
                 "user_id" => user_id,
                 "partner_id" => partner_id,
                 "word" => "fneiw"
               })
    end

    test "dialogue/1 returns chat(group chat)", %{chat_member: chat_member} do
      assert {:ok, %Chats{}} =
               Chat.dialogue(%{
                 "user_id" => chat_member.user_id,
                 "chat_room_id" => chat_member.chat_room_id,
                 "word" => "dmsk"
               })
    end

    test "dialogue/1 notification(group chat)", %{chat_member: chat_member} do
      token = "asdftokentoken"

      Accounts.register_device(chat_member.user_id, token)

      assert {:ok, %Chats{}} =
               Chat.dialogue(%{
                 "user_id" => chat_member.user_id,
                 "chat_room_id" => chat_member.chat_room_id,
                 "word" => "dmsk"
               })
    end
  end

  describe "chat_member" do
    alias Milk.Chat.ChatMember

    @update_attrs %{authority: 43}
    @invalid_attrs %{"authority" => nil}

    setup [:create_chat_member]

    test "create_chat_member/1 with valid data creates a chat_member", %{chat_member: chat_member} do
      # assert {:ok, %ChatMember{} = chat_member} = Chat.create_chat_member(@valid_attrs)
      assert chat_member.authority == 42
    end

    test "create_chat_member/1 with invalid data returns an error" do
      assert {:error, _} = Chat.create_chat_member(%{"user_id" => -1, "chat_room_id" => 111})
    end

    test "update_chat_member/2 with valid data updates the chat_member", %{
      chat_member: chat_member
    } do
      assert {:ok, %ChatMember{} = chat_member} = Chat.update_chat_member(chat_member, @update_attrs)

      assert chat_member.authority == 43
    end

    test "delete_chat_member/1 deletes the chat_member", %{chat_member: chat_member} do
      assert {:ok, %ChatMember{}} = Chat.delete_chat_member(chat_member.chat_room_id, chat_member.user_id)

      # assert_raise Ecto.NoResultsError, fn -> Chat.get_chat_member!(chat_member.id) end
    end

    test "get_chat_members_by_tournament_id" do
      tournament = fixture_tournament()

      tournament
      |> Map.get(:id)
      |> Chat.get_uniq_chat_members_by_tournament_id()
      |> Enum.map(fn member ->
        assert member.user_id == tournament.master_id
      end)
      |> length()
      |> Kernel.==(1)
      |> assert()
    end

    test "sync/2 returns all chat rooms with date and id", %{chat_member: chat_member} do
      chat_room = Chat.get_chat_room(chat_member.chat_room_id)
      assert _ = Chat.sync(chat_room.update_time, chat_member.user_id)
    end
  end

  describe "chat" do
    alias Milk.Chat.Chats
    @update_attrs %{word: "some updated word"}
    @invalid_attrs %{"word" => nil}

    setup [:create_chat]

    test "list_chat/1 returns all chat", %{chat: chats} do
      assert Chat.list_chat(%{chat_room_id: chats.chat_room_id, max: 999, min: 0}) == [chats]
    end

    test "create_chats/1 with valid data creates a chats", %{chat: chats} do
      assert chats.word == "some word"
    end

    test "update_chats/2 with valid data updates the chats", %{chat: chats} do
      assert {:ok, %Chats{} = chats} = Chat.update_chats(chats, @update_attrs)
      assert chats.index == 43
      assert chats.word == "some updated word"
    end

    test "update_chats/2 with invalid data returns error changeset", %{chat: chats} do
      assert {:error, %Ecto.Changeset{}} = Chat.update_chats(chats, @invalid_attrs)
      assert chats == Chat.get_chat(chats.chat_room_id, chats.index)
    end

    test "delete_chats/1 deletes the chats", %{chat: chats} do
      assert {:ok, %Chats{}} = Chat.delete_chats(chats)
      assert nil == Chat.get_chat(chats.chat_room_id, chats.index)
    end

    test "sync/1 gets all chats from user_id", %{user_id: user_id} do
      assert [%{"data" => _, "room_id" => _}] = Chat.sync(user_id)
    end

    test "get_latest_chat gets a latest chat", %{
      chat: chats,
      chat_room_id: chat_room_id
    } do
      assert Chat.get_latest_chat(chat_room_id) == [chats]
    end
  end
end

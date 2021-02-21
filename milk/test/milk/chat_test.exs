defmodule Milk.ChatTest do
  use Milk.DataCase

  alias Milk.Chat
  alias Milk.Accounts
  alias Milk.Chat.ChatRoom

  describe "chat_room" do
    @valid_attrs %{count: 42, last_chat: "some last_chat", name: "some name"}
    @update_attrs %{count: 43, last_chat: "some updated last_chat", name: "some updated name"}
    @invalid_attrs %{count: nil, last_chat: nil, name: "aa"}
    @user_valid_attrs %{"icon_path" => "some icon_path", "language" => "some language", "name" => "some name", "notification_number" => 42, "point" => 42, "email" => "some@email.com", "logout_fl" => true, "password" => "S1ome password"}

    def chat_room_fixture(attrs \\ %{}) do
      {:ok, chat_room} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Chat.create_chat_room()

      Chat.get_chat_room(chat_room.id)
    end

    defp user_fixture(name \\ "name", email \\ "email") do
      {:ok, user} =
        %{}
        |> Enum.into(@user_valid_attrs)
        |> Map.put("name", name)
        |> Map.put("email", email)
        |> Accounts.create_user()

      Accounts.get_user(user.id)
    end

    test "get_chat_room/1 returns the chat_room with given id" do
      chat_room = chat_room_fixture()
      assert Chat.get_chat_room(chat_room.id) == chat_room
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

    test "update_chat_room/2 with valid data updates the chat_room" do
      chat_room = chat_room_fixture()
      assert {:ok, %ChatRoom{} = chat_room} = Chat.update_chat_room(chat_room, @update_attrs)
      assert chat_room.count == 43
      assert chat_room.last_chat == "some updated last_chat"
      assert chat_room.name == "some updated name"
    end

    test "update_chat_room/2 with invalid data returns error changeset" do
      chat_room = chat_room_fixture()
      assert {:error, %Ecto.Changeset{}} = Chat.update_chat_room(chat_room, @invalid_attrs)
      assert chat_room == Chat.get_chat_room(chat_room.id)
    end

    test "delete_chat_room/1 deletes the chat_room" do
      chat_room = chat_room_fixture()
      assert {:ok, %ChatRoom{}} = Chat.delete_chat_room(chat_room)
      assert !Chat.get_chat_room(chat_room.id)
    end

    test "change_chat_room/1 returns a chat_room changeset" do
      chat_room = chat_room_fixture()
      assert %Ecto.Changeset{} = Chat.change_chat_room(chat_room)
    end
  end

  describe "chat_member" do
    alias Milk.Chat.ChatMember

    @update_attrs %{authority: 43}
    @invalid_attrs %{"authority" => nil}
    @room_attrs %{count: 42, last_chat: "some last_chat", name: "some name"}
    @user_attrs %{"icon_path" => "some icon_path", "language" => "some language", "name" => "some name", "notification_number" => 42, "point"  =>  42, "email" => "some email", "logout_fl" => true, "password" => "S1ome password"}

    def chat_member_fixture(attrs \\ %{}) do
      {:ok, user} = Accounts.create_user(@user_attrs)
      {:ok, chat_room} = Chat.create_chat_room(@room_attrs)
      {:ok, chat_member} = attrs |> Enum.into(%{"authority" => 42})
      |> Map.put("chat_room_id", chat_room.id)
      |> Map.put("user_id", user.id)
      |> Chat.create_chat_member()

      chat_member
      |> Map.put(:chat_room_id, chat_room.id)
      |> Map.put(:user_id, user.id)
    end

    test "create_chat_member/1 with valid data creates a chat_member" do
      # assert {:ok, %ChatMember{} = chat_member} = Chat.create_chat_member(@valid_attrs)
      chat_member = chat_member_fixture()
      assert chat_member.authority == 42
    end

    test "update_chat_member/2 with valid data updates the chat_member" do
      chat_member = chat_member_fixture()
      assert {:ok, %ChatMember{} = chat_member} = Chat.update_chat_member(chat_member, @update_attrs)
      assert chat_member.authority == 43
    end

    test "delete_chat_member/1 deletes the chat_member" do
      chat_member = chat_member_fixture()
      assert {:ok, %ChatMember{}} = Chat.delete_chat_member(chat_member.chat_room_id,chat_member.user_id)
      # assert_raise Ecto.NoResultsError, fn -> Chat.get_chat_member!(chat_member.id) end
    end
  end

  describe "chat" do
    alias Milk.Chat.Chats
    @room_attrs %{count: 42, last_chat: "some last_chat", name: "some name"}
    @member_attrs %{"authority" => 42}
    @update_attrs %{word: "some updated word"}
    @invalid_attrs %{"word" => nil}
    @user_attrs %{"icon_path" => "some icon_path", "language" => "some language", "name" => "some name", "notification_number" => 42, "point"  =>  42, "email" => "some email", "logout_fl" => true, "password" => "S1ome password"}

    def chats_fixture(attrs \\ %{}) do
      {:ok, user} = Accounts.create_user(@user_attrs)
      {:ok, chat_room} = Chat.create_chat_room(@room_attrs)
      {:ok, _chat_member} =
        @member_attrs
        |> Map.put("chat_room_id", chat_room.id)
        |> Map.put("user_id", user.id)
        |> Chat.create_chat_member()
      {:ok, chats} =
      attrs |> Enum.into(%{"word" => "some word"})
        |> Map.put("user_id", user.id)
        |> Map.put("chat_room_id", chat_room.id)
        |> Chat.create_chats()

      Chat.get_chat(chat_room.id, chats.index)
    end

    test "list_chat/1 returns all chat" do
      chats = chats_fixture()
      assert Chat.list_chat(%{chat_room_id: chats.chat_room_id, max: 999, min: 0}) == [chats]
    end

    test "create_chats/1 with valid data creates a chats" do
      chats = chats_fixture()
      assert chats.word == "some word"
    end

    test "update_chats/2 with valid data updates the chats" do
      chats = chats_fixture()
      assert {:ok, %Chats{} = chats} = Chat.update_chats(chats, @update_attrs)
      assert chats.index == 43
      assert chats.word == "some updated word"
    end

    test "update_chats/2 with invalid data returns error changeset" do
      chats = chats_fixture()
      assert {:error, %Ecto.Changeset{}} = Chat.update_chats(chats, @invalid_attrs)
      assert chats == Chat.get_chat(chats.chat_room_id, chats.index)
    end

    test "delete_chats/1 deletes the chats" do
      chats = chats_fixture()
      assert {:ok, %Chats{}} = Chat.delete_chats(chats)
      assert nil == Chat.get_chat(chats.chat_room_id, chats.index)
    end
  end

  describe "get_private_chat_room" do
    test "get_private_chat_room works fine" do
      user1 = user_fixture("user1", "user1@gmail.com")
      user2 = user_fixture("user2", "user2@gmail.com")
      room = Chat.get_private_chat_room(user1.id, user2.id)
      assert room == {:error, :notfound}
    end
  end
end

defmodule Milk.ChatTest do
  use Milk.DataCase

  alias Milk.Chat
  alias Milk.Accounts

  describe "chat_room" do
    alias Milk.Chat.ChatRoom

    @valid_attrs %{count: 42, last_chat: "some last_chat", name: "some name"}
    @update_attrs %{count: 43, last_chat: "some updated last_chat", name: "some updated name"}
    @invalid_attrs %{count: nil, last_chat: nil, name: "aa"}

    def chat_room_fixture(attrs \\ %{}) do
      {:ok, chat_room} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Chat.create_chat_room()

      Chat.get_chat_room(chat_room.id)
    end

    test "list_chat_room/0 returns all chat_room" do
      chat_room = chat_room_fixture()
      assert Chat.list_chat_room() == [chat_room]
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

    @valid_attrs %{authority: 42}
    @update_attrs %{authority: 43}
    @invalid_attrs %{"authority" => nil}
    @room_attrs %{count: 42, last_chat: "some last_chat", name: "some name"}
    @user_attrs %{icon_path: "some icon_path", language: "some language", name: "some name", notification_number: 42, point: 42,email: "some email", logout_fl: true, password: "some password"}

    def chat_member_fixture(attrs \\ %{}) do
      {:ok, user} = Accounts.create_user(@user_attrs)
      {:ok, chat_room} = Chat.create_chat_room(@room_attrs)
      {:ok, chat_member} = attrs |> Enum.into(%{"authority" => 42})
      |> Map.put("chat_room_id", chat_room.id)
      |> Map.put("user_id", user.id)
      |> Chat.create_chat_member()

      chat_member|>IO.inspect(label: :chat_debug7)
      |> Map.put(:chat_room_id, chat_room.id)
      |> Map.put(:user_id, user.id)
    end

    # test "list_chat_member/0 returns all chat_member" do
    #   chat_member = chat_member_fixture()
    #   assert Chat.list_chat_member() == [chat_member]
    # end
    #fix me
    # test "get_chat_member/1 returns the chat_member with given id" do
    #   chat_member = chat_member_fixture()
    #   assert Chat.get_chat_member!(chat_member.id) == chat_member
    # end

    test "create_chat_member/1 with valid data creates a chat_member" do
      # assert {:ok, %ChatMember{} = chat_member} = Chat.create_chat_member(@valid_attrs)
      chat_member = chat_member_fixture()
      assert chat_member.authority == 42
    end
# fix me
    # test "create_chat_member/1 with invalid data returns error" do
    #   chat = chat_member_fixture(@invalid_attrs)
    #   assert {:error, _} = chat
    # end

    test "update_chat_member/2 with valid data updates the chat_member" do
      chat_member = chat_member_fixture()
      assert {:ok, %ChatMember{} = chat_member} = Chat.update_chat_member(chat_member, @update_attrs)
      assert chat_member.authority == 43
    end

    # test "update_chat_member/2 with invalid data returns error changeset" do
    #   chat_member = chat_member_fixture()
    #   assert {:error, %Ecto.Changeset{}} = Chat.update_chat_member(chat_member, @invalid_attrs)
    #   assert chat_member == Chat.get_chat_member(chat_member.id)
    # end

    test "delete_chat_member/1 deletes the chat_member" do
      chat_member = chat_member_fixture()
      assert {:ok, %ChatMember{}} = chat_member |> Chat.delete_chat_member()
      # assert_raise Ecto.NoResultsError, fn -> Chat.get_chat_member!(chat_member.id) end
    end

  #   test "change_chat_member/1 returns a chat_member changeset" do
  #     chat_member = chat_member_fixture()
  #     assert %Ecto.Changeset{} = Chat.change_chat_member(chat_member)
  #   end
  end

  describe "chat" do
    alias Milk.Chat.Chats
    @room_attrs %{count: 42, last_chat: "some last_chat", name: "some name"}
    @member_attrs %{"authority" => 42}
    @valid_attrs %{word: "some word"}
    @update_attrs %{word: "some updated word"}
    @invalid_attrs %{"word" => nil}
    @user_attrs %{icon_path: "some icon_path", language: "some language", name: "some name", notification_number: 42, point: 42,email: "some email", logout_fl: true, password: "some password"}

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

    test "get_chat/1 returns the chats with given id" do
      chats = chats_fixture()
      assert Chat.get_chat(chats.chat_room_id, chats.index) == chats
    end

    test "create_chats/1 with valid data creates a chats" do
      chats = chats_fixture()
      assert chats.word == "some word"
    end

    test "create_chats/1 with invalid data returns error changeset" do
      assert {:error, _} = chats_fixture(@invalid_attrs)
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

    # test "change_chats/1 returns a chats changeset" do
    #   chats = chats_fixture()
    #   assert %Ecto.Changeset{} = Chat.change_chats(chats)
    # end
  end
end

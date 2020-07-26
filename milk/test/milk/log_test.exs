defmodule Milk.LogTest do
  use Milk.DataCase

  alias Milk.Log

  describe "chat_room_log" do
    alias Milk.Log.ChatRoomLog

    @valid_attrs %{count: 42, last_chat: "some last_chat", name: "some name"}
    @update_attrs %{count: 43, last_chat: "some updated last_chat", name: "some updated name"}
    @invalid_attrs %{count: nil, last_chat: nil, name: nil}

    def chat_room_log_fixture(attrs \\ %{}) do
      {:ok, chat_room_log} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Log.create_chat_room_log()

      chat_room_log
    end

    test "list_chat_room_log/0 returns all chat_room_log" do
      chat_room_log = chat_room_log_fixture()
      assert Log.list_chat_room_log() == [chat_room_log]
    end

    test "get_chat_room_log!/1 returns the chat_room_log with given id" do
      chat_room_log = chat_room_log_fixture()
      assert Log.get_chat_room_log!(chat_room_log.id) == chat_room_log
    end

    test "create_chat_room_log/1 with valid data creates a chat_room_log" do
      assert {:ok, %ChatRoomLog{} = chat_room_log} = Log.create_chat_room_log(@valid_attrs)
      assert chat_room_log.count == 42
      assert chat_room_log.last_chat == "some last_chat"
      assert chat_room_log.name == "some name"
    end

    test "create_chat_room_log/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Log.create_chat_room_log(@invalid_attrs)
    end

    test "update_chat_room_log/2 with valid data updates the chat_room_log" do
      chat_room_log = chat_room_log_fixture()
      assert {:ok, %ChatRoomLog{} = chat_room_log} = Log.update_chat_room_log(chat_room_log, @update_attrs)
      assert chat_room_log.count == 43
      assert chat_room_log.last_chat == "some updated last_chat"
      assert chat_room_log.name == "some updated name"
    end

    test "update_chat_room_log/2 with invalid data returns error changeset" do
      chat_room_log = chat_room_log_fixture()
      assert {:error, %Ecto.Changeset{}} = Log.update_chat_room_log(chat_room_log, @invalid_attrs)
      assert chat_room_log == Log.get_chat_room_log!(chat_room_log.id)
    end

    test "delete_chat_room_log/1 deletes the chat_room_log" do
      chat_room_log = chat_room_log_fixture()
      assert {:ok, %ChatRoomLog{}} = Log.delete_chat_room_log(chat_room_log)
      assert_raise Ecto.NoResultsError, fn -> Log.get_chat_room_log!(chat_room_log.id) end
    end

    test "change_chat_room_log/1 returns a chat_room_log changeset" do
      chat_room_log = chat_room_log_fixture()
      assert %Ecto.Changeset{} = Log.change_chat_room_log(chat_room_log)
    end
  end

  describe "chat_member_log" do
    alias Milk.Log.ChatMemberLog

    @valid_attrs %{authority: 42, chat_room_id: 42, user_id: 42}
    @update_attrs %{authority: 43, chat_room_id: 43, user_id: 43}
    @invalid_attrs %{authority: nil, chat_room_id: nil, user_id: nil}

    def chat_member_log_fixture(attrs \\ %{}) do
      {:ok, chat_member_log} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Log.create_chat_member_log()

      chat_member_log
    end

    test "list_chat_member_log/0 returns all chat_member_log" do
      chat_member_log = chat_member_log_fixture()
      assert Log.list_chat_member_log() == [chat_member_log]
    end

    test "get_chat_member_log!/1 returns the chat_member_log with given id" do
      chat_member_log = chat_member_log_fixture()
      assert Log.get_chat_member_log!(chat_member_log.id) == chat_member_log
    end

    test "create_chat_member_log/1 with valid data creates a chat_member_log" do
      assert {:ok, %ChatMemberLog{} = chat_member_log} = Log.create_chat_member_log(@valid_attrs)
      assert chat_member_log.authority == 42
      assert chat_member_log.chat_room_id == 42
      assert chat_member_log.user_id == 42
    end

    test "create_chat_member_log/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Log.create_chat_member_log(@invalid_attrs)
    end

    test "update_chat_member_log/2 with valid data updates the chat_member_log" do
      chat_member_log = chat_member_log_fixture()
      assert {:ok, %ChatMemberLog{} = chat_member_log} = Log.update_chat_member_log(chat_member_log, @update_attrs)
      assert chat_member_log.authority == 43
      assert chat_member_log.chat_room_id == 43
      assert chat_member_log.user_id == 43
    end

    test "update_chat_member_log/2 with invalid data returns error changeset" do
      chat_member_log = chat_member_log_fixture()
      assert {:error, %Ecto.Changeset{}} = Log.update_chat_member_log(chat_member_log, @invalid_attrs)
      assert chat_member_log == Log.get_chat_member_log!(chat_member_log.id)
    end

    test "delete_chat_member_log/1 deletes the chat_member_log" do
      chat_member_log = chat_member_log_fixture()
      assert {:ok, %ChatMemberLog{}} = Log.delete_chat_member_log(chat_member_log)
      assert_raise Ecto.NoResultsError, fn -> Log.get_chat_member_log!(chat_member_log.id) end
    end

    test "change_chat_member_log/1 returns a chat_member_log changeset" do
      chat_member_log = chat_member_log_fixture()
      assert %Ecto.Changeset{} = Log.change_chat_member_log(chat_member_log)
    end
  end

  describe "chat_log" do
    alias Milk.Log.ChatsLog

    @valid_attrs %{chat_room_id: 42, index: 42, user_id: 42, word: "some word"}
    @update_attrs %{chat_room_id: 43, index: 43, user_id: 43, word: "some updated word"}
    @invalid_attrs %{chat_room_id: nil, index: nil, user_id: nil, word: nil}

    def chats_log_fixture(attrs \\ %{}) do
      {:ok, chats_log} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Log.create_chats_log()

      chats_log
    end

    test "list_chat_log/0 returns all chat_log" do
      chats_log = chats_log_fixture()
      assert Log.list_chat_log() == [chats_log]
    end

    test "get_chats_log!/1 returns the chats_log with given id" do
      chats_log = chats_log_fixture()
      assert Log.get_chats_log!(chats_log.id) == chats_log
    end

    test "create_chats_log/1 with valid data creates a chats_log" do
      assert {:ok, %ChatsLog{} = chats_log} = Log.create_chats_log(@valid_attrs)
      assert chats_log.chat_room_id == 42
      assert chats_log.index == 42
      assert chats_log.user_id == 42
      assert chats_log.word == "some word"
    end

    test "create_chats_log/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Log.create_chats_log(@invalid_attrs)
    end

    test "update_chats_log/2 with valid data updates the chats_log" do
      chats_log = chats_log_fixture()
      assert {:ok, %ChatsLog{} = chats_log} = Log.update_chats_log(chats_log, @update_attrs)
      assert chats_log.chat_room_id == 43
      assert chats_log.index == 43
      assert chats_log.user_id == 43
      assert chats_log.word == "some updated word"
    end

    test "update_chats_log/2 with invalid data returns error changeset" do
      chats_log = chats_log_fixture()
      assert {:error, %Ecto.Changeset{}} = Log.update_chats_log(chats_log, @invalid_attrs)
      assert chats_log == Log.get_chats_log!(chats_log.id)
    end

    test "delete_chats_log/1 deletes the chats_log" do
      chats_log = chats_log_fixture()
      assert {:ok, %ChatsLog{}} = Log.delete_chats_log(chats_log)
      assert_raise Ecto.NoResultsError, fn -> Log.get_chats_log!(chats_log.id) end
    end

    test "change_chats_log/1 returns a chats_log changeset" do
      chats_log = chats_log_fixture()
      assert %Ecto.Changeset{} = Log.change_chats_log(chats_log)
    end
  end
end

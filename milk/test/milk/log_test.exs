defmodule Milk.LogTest do
  use Milk.DataCase
  use Common.Fixtures

  import Common.Sperm

  alias Milk.Log
  alias Milk.Chat

  describe "chat_room_log" do
    alias Milk.Log.ChatRoomLog

    @valid_attrs %{count: 42, last_chat: "some last_chat", name: "some name"}
    @update_attrs %{count: 43, last_chat: "some updated last_chat", name: "some updated name"}
    @invalid_attrs %{count: nil, last_chat: nil, name: nil}

    def chat_room_log_fixture(attrs \\ %{}) do
      {:ok, chat_room} = Chat.create_chat_room(%{"name" => "some name"})

      {:ok, chat_room_log} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Map.put(:id, chat_room.id)
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
      assert %ChatRoomLog{} = chat_room_log = chat_room_log_fixture()
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

  describe "entrant_log" do
    alias Milk.Log.EntrantLog

    @valid_attrs %{
      entrant_id: 42,
      rank: 42,
      tournament_id: 42,
      user_id: 42,
      create_time: ~U[2020-12-20 16:29:01.100311Z],
      update_time: ~U[2020-12-20 16:29:01.100311Z]
    }
    @update_attrs %{entrant_id: 42, rank: 43, tournament_id: 43, user_id: 43}
    @invalid_attrs %{entrant_id: 42, rank: nil, tournament_id: nil, user_id: nil}

    def entrant_log_fixture(attrs \\ %{}) do
      {:ok, entrant_log} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Log.create_entrant_log()

      entrant_log
    end

    test "list_entrant_log/0 returns all entrant_log" do
      entrant_log_fixture()
      entrant_logs = Log.list_entrant_log()
      assert is_list(entrant_logs)
      refute length(entrant_logs) == 0

      Enum.each(entrant_logs, fn log ->
        assert %EntrantLog{} = log
      end)
    end

    test "get_entrant_log!/1 returns the entrant_log with given id" do
      entrant_log = entrant_log_fixture()
      assert Log.get_entrant_log!(entrant_log.id).id == entrant_log.id
    end

    test "create_entrant_log/1 with valid data creates a entrant_log" do
      assert {:ok, %EntrantLog{} = entrant_log} = Log.create_entrant_log(@valid_attrs)
      assert entrant_log.rank == 42
      assert entrant_log.tournament_id == 42
      assert entrant_log.user_id == 42
    end

    test "create_entrant_log/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Log.create_entrant_log(@invalid_attrs)
    end

    test "update_entrant_log/2 with valid data updates the entrant_log" do
      entrant_log = entrant_log_fixture()

      assert {:ok, %EntrantLog{} = entrant_log} = Log.update_entrant_log(entrant_log, @update_attrs)

      assert entrant_log.rank == 43
      assert entrant_log.tournament_id == 43
      assert entrant_log.user_id == 43
    end

    test "update_entrant_log/2 with invalid data returns error changeset" do
      entrant_log = entrant_log_fixture()
      assert {:error, %Ecto.Changeset{}} = Log.update_entrant_log(entrant_log, @invalid_attrs)
      assert entrant_log.id == Log.get_entrant_log!(entrant_log.id).id
    end

    test "delete_entrant_log/1 deletes the entrant_log" do
      entrant_log = entrant_log_fixture()
      assert {:ok, %EntrantLog{}} = Log.delete_entrant_log(entrant_log)
      assert_raise Ecto.NoResultsError, fn -> Log.get_entrant_log!(entrant_log.id) end
    end

    test "change_entrant_log/1 returns a entrant_log changeset" do
      entrant_log = entrant_log_fixture()
      assert %Ecto.Changeset{} = Log.change_entrant_log(entrant_log)
    end
  end

  describe "tournament_log" do
    alias Milk.Log.TournamentLog

    @valid_attrs %{name: "some name", create_time: "time"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    def tournament_log_fixture(attrs \\ %{}) do
      {:ok, tournament_log} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Log.create_tournament_log()

      tournament_log
    end

    test "list_tournament_log/0 returns all tournament_log" do
      tournament_log_fixture()
      tournament_logs = Log.list_tournament_log()
      assert is_list(tournament_logs)
      refute length(tournament_logs) == 0

      Enum.each(tournament_logs, fn log ->
        assert %TournamentLog{} = log
      end)
    end

    test "get_tournament_log!/1 returns the tournament_log with given id" do
      tournament_log = tournament_log_fixture()
      assert Log.get_tournament_log!(tournament_log.id).id == tournament_log.id
    end

    test "create_tournament_log/1 with valid data creates a tournament_log" do
      assert {:ok, %TournamentLog{} = tournament_log} = Log.create_tournament_log(@valid_attrs)
      assert tournament_log.name == "some name"
    end

    test "create_tournament_log/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Log.create_tournament_log(@invalid_attrs)
    end

    test "update_tournament_log/2 with valid data updates the tournament_log" do
      tournament_log = tournament_log_fixture()

      assert {:ok, %TournamentLog{} = tournament_log} = Log.update_tournament_log(tournament_log, @update_attrs)

      assert tournament_log.name == "some updated name"
    end

    test "update_tournament_log/2 with invalid data returns error changeset" do
      tournament_log = tournament_log_fixture()

      assert {:error, %Ecto.Changeset{}} = Log.update_tournament_log(tournament_log, @invalid_attrs)

      assert tournament_log.id == Log.get_tournament_log!(tournament_log.id).id
    end

    test "delete_tournament_log/1 deletes the tournament_log" do
      tournament_log = tournament_log_fixture()
      assert {:ok, %TournamentLog{}} = Log.delete_tournament_log(tournament_log)
      refute Log.get_tournament_log!(tournament_log.id)
    end
  end

  describe "team_log" do
    test "create team log (team_id)" do
      [is_team: true, capacity: 4, type: 2]
      |> fixture_tournament()
      |> Map.get(:id)
      ~> tournament_id
      |> fill_with_team()
      ~> teams
      |> Enum.map(& &1.id)
      ~> team_id_list
      |> Enum.each(fn team_id ->
        Log.create_team_log(team_id)
      end)

      team_id_list
      |> Enum.map(fn team_id ->
        Log.get_team_log_by_team_id(team_id)
      end)
      |> Enum.each(fn log ->
        assert log.tournament_id == tournament_id
        assert log.team_id in team_id_list
        assert length(log.team_member) == 5
        refute is_nil(log.rank)
      end)

      teams
      |> hd()
      |> Map.get(:tournament_id)
      ~> tournament_id

      teams
      |> hd()
      |> Map.get(:team_member)
      |> hd()
      |> Map.get(:user_id)
      ~> user_id

      team_id = hd(teams).id

      #assert Log.get_team_log_by_team_id(team_id) == Log.get_team_log_by_tournament_id_and_user_id(tournament_id, user_id)
    end
  end
end

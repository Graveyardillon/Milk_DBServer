defmodule Milk.TournamentsTest do
  use Milk.DataCase

  alias Milk.Tournaments

  describe "tournament" do
    alias Milk.Tournaments.Tournament

    @valid_attrs %{capacity: 42, deadline: "2010-04-17T14:00:00Z", description: "some description", event_date: "2010-04-17T14:00:00Z", name: "some name", type: 42, url: "some url"}
    @update_attrs %{capacity: 43, deadline: "2011-05-18T15:01:01Z", description: "some updated description", event_date: "2011-05-18T15:01:01Z", name: "some updated name", type: 43, url: "some updated url"}
    @invalid_attrs %{capacity: nil, deadline: nil, description: nil, event_date: nil, name: nil, type: nil, url: nil}

    def tournament_fixture(attrs \\ %{}) do
      {:ok, tournament} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Tournaments.create_tournament()

      tournament
    end

    test "list_tournament/0 returns all tournament" do
      tournament = tournament_fixture()
      assert Tournaments.list_tournament() == [tournament]
    end

    test "get_tournament!/1 returns the tournament with given id" do
      tournament = tournament_fixture()
      assert Tournaments.get_tournament!(tournament.id) == tournament
    end

    test "create_tournament/1 with valid data creates a tournament" do
      assert {:ok, %Tournament{} = tournament} = Tournaments.create_tournament(@valid_attrs)
      assert tournament.capacity == 42
      assert tournament.deadline == DateTime.from_naive!(~N[2010-04-17T14:00:00Z], "Etc/UTC")
      assert tournament.description == "some description"
      assert tournament.event_date == DateTime.from_naive!(~N[2010-04-17T14:00:00Z], "Etc/UTC")
      assert tournament.name == "some name"
      assert tournament.type == 42
      assert tournament.url == "some url"
    end

    test "create_tournament/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tournaments.create_tournament(@invalid_attrs)
    end

    test "update_tournament/2 with valid data updates the tournament" do
      tournament = tournament_fixture()
      assert {:ok, %Tournament{} = tournament} = Tournaments.update_tournament(tournament, @update_attrs)
      assert tournament.capacity == 43
      assert tournament.deadline == DateTime.from_naive!(~N[2011-05-18T15:01:01Z], "Etc/UTC")
      assert tournament.description == "some updated description"
      assert tournament.event_date == DateTime.from_naive!(~N[2011-05-18T15:01:01Z], "Etc/UTC")
      assert tournament.name == "some updated name"
      assert tournament.type == 43
      assert tournament.url == "some updated url"
    end

    test "update_tournament/2 with invalid data returns error changeset" do
      tournament = tournament_fixture()
      assert {:error, %Ecto.Changeset{}} = Tournaments.update_tournament(tournament, @invalid_attrs)
      assert tournament == Tournaments.get_tournament!(tournament.id)
    end

    test "delete_tournament/1 deletes the tournament" do
      tournament = tournament_fixture()
      assert {:ok, %Tournament{}} = Tournaments.delete_tournament(tournament)
      assert_raise Ecto.NoResultsError, fn -> Tournaments.get_tournament!(tournament.id) end
    end

    test "change_tournament/1 returns a tournament changeset" do
      tournament = tournament_fixture()
      assert %Ecto.Changeset{} = Tournaments.change_tournament(tournament)
    end
  end

  describe "entrant" do
    alias Milk.Tournaments.Entrant

    @valid_attrs %{rank: 42}
    @update_attrs %{rank: 43}
    @invalid_attrs %{rank: nil}

    def entrant_fixture(attrs \\ %{}) do
      {:ok, entrant} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Tournaments.create_entrant()

      entrant
    end

    test "list_entrant/0 returns all entrant" do
      entrant = entrant_fixture()
      assert Tournaments.list_entrant() == [entrant]
    end

    test "get_entrant!/1 returns the entrant with given id" do
      entrant = entrant_fixture()
      assert Tournaments.get_entrant!(entrant.id) == entrant
    end

    test "create_entrant/1 with valid data creates a entrant" do
      assert {:ok, %Entrant{} = entrant} = Tournaments.create_entrant(@valid_attrs)
      assert entrant.rank == 42
    end

    test "create_entrant/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tournaments.create_entrant(@invalid_attrs)
    end

    test "update_entrant/2 with valid data updates the entrant" do
      entrant = entrant_fixture()
      assert {:ok, %Entrant{} = entrant} = Tournaments.update_entrant(entrant, @update_attrs)
      assert entrant.rank == 43
    end

    test "update_entrant/2 with invalid data returns error changeset" do
      entrant = entrant_fixture()
      assert {:error, %Ecto.Changeset{}} = Tournaments.update_entrant(entrant, @invalid_attrs)
      assert entrant == Tournaments.get_entrant!(entrant.id)
    end

    test "delete_entrant/1 deletes the entrant" do
      entrant = entrant_fixture()
      assert {:ok, %Entrant{}} = Tournaments.delete_entrant(entrant)
      assert_raise Ecto.NoResultsError, fn -> Tournaments.get_entrant!(entrant.id) end
    end

    test "change_entrant/1 returns a entrant changeset" do
      entrant = entrant_fixture()
      assert %Ecto.Changeset{} = Tournaments.change_entrant(entrant)
    end
  end

  describe "assistant" do
    alias Milk.Tournaments.Assistant

    @valid_attrs %{}
    @update_attrs %{}
    @invalid_attrs %{}

    def assistant_fixture(attrs \\ %{}) do
      {:ok, assistant} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Tournaments.create_assistant()

      assistant
    end

    test "list_assistant/0 returns all assistant" do
      assistant = assistant_fixture()
      assert Tournaments.list_assistant() == [assistant]
    end

    test "get_assistant!/1 returns the assistant with given id" do
      assistant = assistant_fixture()
      assert Tournaments.get_assistant!(assistant.id) == assistant
    end

    test "create_assistant/1 with valid data creates a assistant" do
      assert {:ok, %Assistant{} = assistant} = Tournaments.create_assistant(@valid_attrs)
    end

    test "create_assistant/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tournaments.create_assistant(@invalid_attrs)
    end

    test "update_assistant/2 with valid data updates the assistant" do
      assistant = assistant_fixture()
      assert {:ok, %Assistant{} = assistant} = Tournaments.update_assistant(assistant, @update_attrs)
    end

    test "update_assistant/2 with invalid data returns error changeset" do
      assistant = assistant_fixture()
      assert {:error, %Ecto.Changeset{}} = Tournaments.update_assistant(assistant, @invalid_attrs)
      assert assistant == Tournaments.get_assistant!(assistant.id)
    end

    test "delete_assistant/1 deletes the assistant" do
      assistant = assistant_fixture()
      assert {:ok, %Assistant{}} = Tournaments.delete_assistant(assistant)
      assert_raise Ecto.NoResultsError, fn -> Tournaments.get_assistant!(assistant.id) end
    end

    test "change_assistant/1 returns a assistant changeset" do
      assistant = assistant_fixture()
      assert %Ecto.Changeset{} = Tournaments.change_assistant(assistant)
    end
  end

  describe "tournament" do
    alias Milk.Tournaments.Tournament

    @valid_attrs %{user_id: 42}
    @update_attrs %{user_id: 43}
    @invalid_attrs %{user_id: nil}

    def tournament_fixture(attrs \\ %{}) do
      {:ok, tournament} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Tournaments.create_tournament()

      tournament
    end

    test "list_tournament/0 returns all tournament" do
      tournament = tournament_fixture()
      assert Tournaments.list_tournament() == [tournament]
    end

    test "get_tournament!/1 returns the tournament with given id" do
      tournament = tournament_fixture()
      assert Tournaments.get_tournament!(tournament.id) == tournament
    end

    test "create_tournament/1 with valid data creates a tournament" do
      assert {:ok, %Tournament{} = tournament} = Tournaments.create_tournament(@valid_attrs)
      assert tournament.user_id == 42
    end

    test "create_tournament/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tournaments.create_tournament(@invalid_attrs)
    end

    test "update_tournament/2 with valid data updates the tournament" do
      tournament = tournament_fixture()
      assert {:ok, %Tournament{} = tournament} = Tournaments.update_tournament(tournament, @update_attrs)
      assert tournament.user_id == 43
    end

    test "update_tournament/2 with invalid data returns error changeset" do
      tournament = tournament_fixture()
      assert {:error, %Ecto.Changeset{}} = Tournaments.update_tournament(tournament, @invalid_attrs)
      assert tournament == Tournaments.get_tournament!(tournament.id)
    end

    test "delete_tournament/1 deletes the tournament" do
      tournament = tournament_fixture()
      assert {:ok, %Tournament{}} = Tournaments.delete_tournament(tournament)
      assert_raise Ecto.NoResultsError, fn -> Tournaments.get_tournament!(tournament.id) end
    end

    test "change_tournament/1 returns a tournament changeset" do
      tournament = tournament_fixture()
      assert %Ecto.Changeset{} = Tournaments.change_tournament(tournament)
    end
  end

  describe "tournament_chat_topics" do
    alias Milk.Tournaments.TournamentChatTopic

    @valid_attrs %{topic_name: "some topic_name"}
    @update_attrs %{topic_name: "some updated topic_name"}
    @invalid_attrs %{topic_name: nil}

    def tournament_chat_topic_fixture(attrs \\ %{}) do
      {:ok, tournament_chat_topic} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Tournaments.create_tournament_chat_topic()

      tournament_chat_topic
    end

    test "list_tournament_chat_topics/0 returns all tournament_chat_topics" do
      tournament_chat_topic = tournament_chat_topic_fixture()
      assert Tournaments.list_tournament_chat_topics() == [tournament_chat_topic]
    end

    test "get_tournament_chat_topic!/1 returns the tournament_chat_topic with given id" do
      tournament_chat_topic = tournament_chat_topic_fixture()
      assert Tournaments.get_tournament_chat_topic!(tournament_chat_topic.id) == tournament_chat_topic
    end

    test "create_tournament_chat_topic/1 with valid data creates a tournament_chat_topic" do
      assert {:ok, %TournamentChatTopic{} = tournament_chat_topic} = Tournaments.create_tournament_chat_topic(@valid_attrs)
      assert tournament_chat_topic.topic_name == "some topic_name"
    end

    test "create_tournament_chat_topic/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tournaments.create_tournament_chat_topic(@invalid_attrs)
    end

    test "update_tournament_chat_topic/2 with valid data updates the tournament_chat_topic" do
      tournament_chat_topic = tournament_chat_topic_fixture()
      assert {:ok, %TournamentChatTopic{} = tournament_chat_topic} = Tournaments.update_tournament_chat_topic(tournament_chat_topic, @update_attrs)
      assert tournament_chat_topic.topic_name == "some updated topic_name"
    end

    test "update_tournament_chat_topic/2 with invalid data returns error changeset" do
      tournament_chat_topic = tournament_chat_topic_fixture()
      assert {:error, %Ecto.Changeset{}} = Tournaments.update_tournament_chat_topic(tournament_chat_topic, @invalid_attrs)
      assert tournament_chat_topic == Tournaments.get_tournament_chat_topic!(tournament_chat_topic.id)
    end

    test "delete_tournament_chat_topic/1 deletes the tournament_chat_topic" do
      tournament_chat_topic = tournament_chat_topic_fixture()
      assert {:ok, %TournamentChatTopic{}} = Tournaments.delete_tournament_chat_topic(tournament_chat_topic)
      assert_raise Ecto.NoResultsError, fn -> Tournaments.get_tournament_chat_topic!(tournament_chat_topic.id) end
    end

    test "change_tournament_chat_topic/1 returns a tournament_chat_topic changeset" do
      tournament_chat_topic = tournament_chat_topic_fixture()
      assert %Ecto.Changeset{} = Tournaments.change_tournament_chat_topic(tournament_chat_topic)
    end
  end

  describe "tournament_user_topic_log" do
    alias Milk.Tournaments.TournamentChatTopicLog

    @valid_attrs %{topic_name: "some topic_name"}
    @update_attrs %{topic_name: "some updated topic_name"}
    @invalid_attrs %{topic_name: nil}

    def tournament_chat_topic_log_fixture(attrs \\ %{}) do
      {:ok, tournament_chat_topic_log} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Tournaments.create_tournament_chat_topic_log()

      tournament_chat_topic_log
    end

    test "list_tournament_user_topic_log/0 returns all tournament_user_topic_log" do
      tournament_chat_topic_log = tournament_chat_topic_log_fixture()
      assert Tournaments.list_tournament_user_topic_log() == [tournament_chat_topic_log]
    end

    test "get_tournament_chat_topic_log!/1 returns the tournament_chat_topic_log with given id" do
      tournament_chat_topic_log = tournament_chat_topic_log_fixture()
      assert Tournaments.get_tournament_chat_topic_log!(tournament_chat_topic_log.id) == tournament_chat_topic_log
    end

    test "create_tournament_chat_topic_log/1 with valid data creates a tournament_chat_topic_log" do
      assert {:ok, %TournamentChatTopicLog{} = tournament_chat_topic_log} = Tournaments.create_tournament_chat_topic_log(@valid_attrs)
      assert tournament_chat_topic_log.topic_name == "some topic_name"
    end

    test "create_tournament_chat_topic_log/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tournaments.create_tournament_chat_topic_log(@invalid_attrs)
    end

    test "update_tournament_chat_topic_log/2 with valid data updates the tournament_chat_topic_log" do
      tournament_chat_topic_log = tournament_chat_topic_log_fixture()
      assert {:ok, %TournamentChatTopicLog{} = tournament_chat_topic_log} = Tournaments.update_tournament_chat_topic_log(tournament_chat_topic_log, @update_attrs)
      assert tournament_chat_topic_log.topic_name == "some updated topic_name"
    end

    test "update_tournament_chat_topic_log/2 with invalid data returns error changeset" do
      tournament_chat_topic_log = tournament_chat_topic_log_fixture()
      assert {:error, %Ecto.Changeset{}} = Tournaments.update_tournament_chat_topic_log(tournament_chat_topic_log, @invalid_attrs)
      assert tournament_chat_topic_log == Tournaments.get_tournament_chat_topic_log!(tournament_chat_topic_log.id)
    end

    test "delete_tournament_chat_topic_log/1 deletes the tournament_chat_topic_log" do
      tournament_chat_topic_log = tournament_chat_topic_log_fixture()
      assert {:ok, %TournamentChatTopicLog{}} = Tournaments.delete_tournament_chat_topic_log(tournament_chat_topic_log)
      assert_raise Ecto.NoResultsError, fn -> Tournaments.get_tournament_chat_topic_log!(tournament_chat_topic_log.id) end
    end

    test "change_tournament_chat_topic_log/1 returns a tournament_chat_topic_log changeset" do
      tournament_chat_topic_log = tournament_chat_topic_log_fixture()
      assert %Ecto.Changeset{} = Tournaments.change_tournament_chat_topic_log(tournament_chat_topic_log)
    end
  end
end

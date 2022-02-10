defmodule Milk.TournamentsTest do
  @moduledoc """
  Tournamentsのテストが記述してあるモジュール
  """
  use Milk.DataCase
  use Common.Fixtures
  use Timex

  import Common.Sperm

  alias Milk.{
    Accounts,
    Chat,
    Games,
    Log,
    Relations,
    Repo,
    Tournaments
  }

  alias Milk.Tournaments.{
    Team,
    TeamInvitation,
    Tournament,
    Entrant,
    Progress,
    TournamentChatTopic
  }

  alias Milk.Log.{
    EntrantLog,
    TournamentLog
  }

  alias Milk.Accounts.User

  require Logger

  @moduletag timeout: 300_000

  # @valid_attrs %{
  #   "capacity" => 42,
  #   "deadline" => "2010-04-17T14:00:00Z",
  #   "description" => "some description",
  #   "event_date" => "2010-04-17T14:00:00Z",
  #   "game_name" => "some game",
  #   "name" => "some name",
  #   "type" => 0,
  #   "url" => "somesomeurl",
  #   "password" => "passwd",
  #   "master_id" => 1,
  #   "platform_id" => 1,
  #   "is_started" => true
  # }
  @valid_attrs %{
    "capacity" => 42,
    "deadline" => nil,
    "description" => "some description",
    "event_date" => nil,
    "game_name" => "some game",
    "name" => "some name",
    "type" => 0,
    "url" => "somesomeurl",
    "password" => "passwd",
    "master_id" => 1,
    "platform_id" => 1,
    "is_started" => true
  }

  @update_attrs %{
    "capacity" => 43,
    "deadline" => "2011-05-18T15:01:01Z",
    "description" => "some updated description",
    "event_date" => "2011-05-18T15:01:01Z",
    "name" => "some updated name",
    "type" => 43,
    "url" => "some updated url"
  }

  @invalid_attrs %{
    "capacity" => nil,
    "deadline" => nil,
    "description" => nil,
    "event_date" => nil,
    "name" => nil,
    "type" => nil,
    "url" => nil,
    "master_id" => 1,
    "platform_id" => 1
  }

  @entrant_create_attrs %{
    "rank" => 42,
    "user_id" => -1,
    "tournament_id" => -1
  }

  @invalid_entrant_create_attrs %{
    "user_id" => nil,
    "tournament_id" => nil
  }

  defp fixture(:game) do
    {:ok, game} = Games.create_game(%{"title" => "Test Game"})
    game
  end

  defp fixture(:assistant) do
    user = fixture_user()

    @valid_attrs
    |> Map.put("master_id", user.id)
    |> Map.put("is_started", false)
    |> Tournaments.create_tournament()
    ~> {:ok, tournament}

    assistant_attrs = %{
      "tournament_id" => tournament.id,
      "user_id" => [user.id]
    }

    {:ok, _users} = Tournaments.create_assistants(assistant_attrs)
    assistant_attrs
  end

  defp fixture(:tournament_chat_topic) do
    tournament = fixture_tournament()
    {:ok, chat_room} = Chat.create_chat_room(%{"name" => "name"})

    Map.new()
    |> Map.put("topic_name", "name")
    |> Map.put("tournament_id", tournament.id)
    |> Map.put("chat_room_id", chat_room.id)
    |> Map.put("tab_index", 1)
    |> Tournaments.create_tournament_chat_topic()
    ~> {:ok, topic}

    topic
  end

  defp fixture_entrant(opts \\ %{}) do
    tournament =
      opts["tournament_id"]
      |> is_nil()
      |> if do
        fixture_tournament(is_started: true)
      else
        Tournaments.load_tournament(opts["tournament_id"])
      end

    opts["user_id"]
    |> is_nil()
    |> if do
      tournament.master_id
    else
      opts["user_id"]
    end
    ~> user_id

    @entrant_create_attrs
    |> Map.put("tournament_id", tournament.id)
    |> Map.put("user_id", user_id)
    |> Tournaments.create_entrant()
    ~> {:ok, entrant}

    entrant
  end

  describe "get tournament" do
    test "load_tournament/1" do
      tournament = fixture_tournament()

      t = Tournaments.load_tournament(tournament.id)
      assert t.capacity == tournament.capacity
      assert t.description == tournament.description
      assert t.name == tournament.name
      assert t.url == tournament.url
      assert t.count == 0
      assert t.entrant == []
      refute t.is_team
      assert t.game_name == tournament.game_name
    end

    test "load_tournament/1 fails" do
      1
      |> Tournaments.load_tournament()
      |> is_nil()
      |> assert()
    end

    test "load_tournament/1 (is_team)" do
      tournament = fixture_tournament(is_team: true)

      assert %Tournament{} = Tournaments.load_tournament(tournament.id)
    end

    test "get_tournament_by_room_id works" do
      tournament = fixture_tournament()

      tournament.id
      |> Chat.get_chat_rooms_by_tournament_id()
      |> Enum.map(fn room ->
        room.id
        |> Tournaments.get_tournament_by_room_id()
        |> then(fn t ->
          assert t.id == tournament.id
        end)
      end)
    end

    test "get_tournament_by_room_id returns nil" do
      -1
      |> Tournaments.get_tournament_by_room_id()
      |> is_nil()
      |> assert()
    end

    test "get_tournaments_by_master_id/1 returns tournaments of a user" do
      tournament = fixture_tournament()

      tournament.master_id
      |> Tournaments.get_tournaments_by_master_id()
      |> Enum.map(fn t ->
        assert t.id == tournament.id
      end)
      |> length()
      |> then(fn len ->
        assert len == 1
      end)
    end

    test "get_tournaments_by_master_id/1 fails to return tournaments of a user" do
      user = fixture_user()
      fixture_tournament()

      user.id
      |> Tournaments.get_tournaments_by_master_id()
      |> Enum.empty?()
      |> assert()
    end

    test "get_tournaments_by_assistant_id/1 fails to returns tournaments of a user" do
      user = fixture_user()
      tournament = fixture_tournament()
      Tournaments.create_assistants(%{"tournament_id" => tournament.id, "user_id" => [user.id]})

      user.id
      |> Tournaments.get_tournaments_by_assistant_id()
      |> Enum.map(fn t ->
        assert t.id == tournament.id
        assert t.game_name == tournament.game_name
        assert t.is_started == tournament.is_started
        assert t.master_id == tournament.master_id
        assert t.name == tournament.name
        assert t.platform_id == tournament.platform_id
        assert t.thumbnail_path == tournament.thumbnail_path
        assert t.url == tournament.url
      end)
      |> length()
      |> then(fn len ->
        assert len == 1
      end)
    end

    test "get_ongoing_tournaments_by_master_id/1 fails to return user's ongoing tournaments" do
      fixture_tournament()
      |> Map.get(:master_id)
      |> Tournaments.get_ongoing_tournaments_by_master_id()
      |> Enum.empty?()
      |> assert()
    end

    test "load_tournament/1 with valid data works fine" do
      tournament = fixture_tournament()
      assert %Tournament{} = obtained_tournament = Tournaments.load_tournament(tournament.id)
      assert obtained_tournament.id == tournament.id
    end

    test "get_participating_tournaments!/1 with valid data works fine" do
      entrant = fixture_entrant()
      _tournament = Tournaments.load_tournament(entrant.tournament_id)

      assert tournaments = Tournaments.get_participating_tournaments(entrant.user_id, 0)
      assert is_list(tournaments)

      Enum.each(tournaments, fn tournament ->
        assert %Tournament{} = tournament
      end)
    end

    test "get_pending_tournaments/1" do
      tournament = fixture_tournament(is_team: true, type: 2)
      user_id = fixture_user(num: 5).id

      6..10
      |> Enum.to_list()
      |> Enum.map(&fixture_user(num: &1))
      |> Enum.map(&Map.get(&1, :id))
      ~> members

      Tournaments.create_team(tournament.id, tournament.team_size, user_id, members)

      user_id
      |> Tournaments.get_pending_tournaments()
      |> Enum.map(fn t ->
        assert t.id == tournament.id
      end)
      |> length()
      |> Kernel.==(1)
      |> assert()

      members
      |> Enum.each(fn member ->
        member
        |> Tournaments.get_team_invitations_by_user_id()
        |> Enum.each(fn invitation ->
          invitation
          |> Map.get(:id)
          |> Tournaments.confirm_team_invitation()
        end)
      end)

      user_id
      |> Tournaments.get_pending_tournaments()
      |> Enum.empty?()
      |> assert()
    end

    test "get_masters/1 with valid data works fine" do
      tournament = fixture_tournament()

      assert users = Tournaments.get_masters(tournament.id)
      assert is_list(users)

      Enum.each(users, fn user ->
        assert %User{} = user
      end)
    end

    test "get_tournament_including_logs/1 with valid data gets tournament from log" do
      user = fixture_user()

      {:ok, tournament} =
        @valid_attrs
        |> Map.put("master_id", user.id)
        |> Tournaments.create_tournament()

      Tournaments.finish(tournament.id, user.id)

      assert {:ok, _tournament} = Tournaments.get_tournament_including_logs(tournament.id)
    end

    test "get_tournament_including_logs/1 with valid data gets tournament" do
      user = fixture_user()

      {:ok, tournament} =
        @valid_attrs
        |> Map.put("master_id", user.id)
        |> Tournaments.create_tournament()

      assert {:ok, _tournament} = Tournaments.get_tournament_including_logs(tournament.id)
    end

    test "get_tournament_including_logs/1 with invalid data does not get tournament" do
      assert {:error, _} = Tournaments.get_tournament_including_logs(-1)
    end
  end

  describe "create tournament" do
    test "create_tournament/1 with valid data creates a tournament" do
      tournament = fixture_tournament()

      assert tournament.capacity == 8
      assert tournament.description == "some description"
      assert tournament.name == "some name"
      assert tournament.url == "some url"
    end

    test "create_tournament/1 with invalid data returns error changeset" do
      assert {:error, _} = Tournaments.create_tournament(@invalid_attrs)
    end
  end

  describe "update_topics" do
    test "works" do
      fixture_tournament()
      ~> tournament
      |> Map.get(:id)
      |> Tournaments.get_tabs_including_logs_by_tourament_id()
      |> Enum.map(fn tab ->
        Map.new()
        |> Map.put(:tab_index, tab.tab_index)
        |> Map.put(:chat_room_id, tab.chat_room_id)
        |> Map.put(:topic_name, tab.topic_name)
      end)
      ~> current_tabs

      current_tabs
      |> Enum.map(fn reg ->
        reg
        |> Enum.map(fn {k, v} -> {Atom.to_string(k), v} end)
        |> Map.new()
      end)
      ~> tabs

      Map.new()
      |> Map.put("tab_index", length(current_tabs))
      |> Map.put("chat_room_id", nil)
      |> Map.put("topic_name", "test")
      ~> tab

      tabs = tabs ++ [tab]

      assert :ok = Tournaments.update_topic(tournament, current_tabs, tabs)

      tournament
      |> Map.get(:id)
      |> Tournaments.get_tabs_including_logs_by_tourament_id()
      |> Enum.map(fn tab ->
        assert tab.topic_name in ["Group", "Notification", "Q&A", "test"]
        assert tab.tournament_id == tournament.id
        refute is_nil(tab.chat_room_id)
      end)
      |> length()
      |> Kernel.==(4)
      |> assert()

      tournament
      |> Map.get(:id)
      |> Chat.get_chat_rooms_by_tournament_id()
      |> Enum.each(fn room ->
        room
        |> Map.get(:id)
        |> Chat.get_chat_members_of_room()
        |> Enum.map(fn member ->
          assert member.user_id == tournament.master_id
        end)
        |> length()
        |> Kernel.==(1)
        |> assert()
      end)
    end
  end

  describe "verify?" do
    test "works" do
      tournament = fixture_tournament()
      assert Tournaments.verify?(tournament.id, "Password123")
      refute Tournaments.verify?(tournament.id, "wrong_pw")
    end
  end

  describe "update tournament" do
    test "update_tournament/2 with valid data updates the tournament" do
      tournament = fixture_tournament()

      assert {:ok, %Tournament{} = tournament} = Tournaments.update_tournament(tournament, @update_attrs)

      assert tournament.capacity == 43
      assert tournament.deadline == "2011-05-18T15:01:01Z"
      assert tournament.description == "some updated description"
      assert tournament.event_date == "2011-05-18T15:01:01Z"
      assert tournament.name == "some updated name"
      assert tournament.url == "some updated url"
    end

    test "update_tournament/2 with invalid data returns error changeset" do
      tournament = fixture_tournament()
      assert {:error, _} = Tournaments.update_tournament(tournament, @invalid_attrs)
    end
  end

  describe "delete tournament" do
    test "delete_tournament/1 of Tournament structure works fine with a valid data and deletes all chat rooms" do
      tournament = fixture_tournament()
      assert {:ok, %Tournament{}} = Tournaments.delete_tournament(tournament)
      refute Tournaments.get_tournament(tournament.id)

      assert Chat.get_chat_rooms_by_tournament_id(tournament.id) == []
      assert Tournaments.get_tabs_by_tournament_id(tournament.id) == []
    end

    test "delete_tournament/1 of map works fine with a valid data" do
      user = fixture_user()

      {:ok, tournament} =
        @valid_attrs
        |> Map.put("master_id", user.id)
        |> Tournaments.create_tournament()

      assert {:ok, %Tournament{}} = Tournaments.delete_tournament(tournament)
      refute Tournaments.load_tournament(tournament.id)
    end

    test "delete_tournament/1 of id works fine with a valid data" do
      tournament = fixture_tournament()
      assert {:ok, %Tournament{}} = Tournaments.delete_tournament(tournament.id)
      refute Tournaments.load_tournament(tournament.id)
    end
  end

  describe "home" do
    @home_attrs %{
      "deadline" => "2031-05-18T15:01:01Z",
      "event_date" => "2031-05-18T15:01:01Z"
    }

    test "home_tournament/3 with user_id and offset" do
      user1 = fixture_user()
      tournament = fixture_tournament()
      offset = 0
      {:ok, _} = Tournaments.update_tournament(tournament, @home_attrs)

      Relations.block(user1.id, tournament.master_id)

      "2020-05-12 16:55:53 +0000"
      |> Tournaments.home_tournament(offset, user1.id)
      |> Enum.empty?()
      |> assert()
    end

    test "home_tournament/3 without user_id" do
      offset = 0
      tournament = fixture_tournament()
      {:ok, _} = Tournaments.update_tournament(tournament, @home_attrs)

      "2020-05-12 16:55:53 +0000"
      |> Tournaments.home_tournament(offset)
      |> length()
      |> Kernel.==(1)
      |> assert()

      offset = 1

      "2020-05-12 16:55:53 +0000"
      |> Tournaments.home_tournament(offset)
      |> Enum.empty?()
      |> assert()
    end

    test "home_tournament_fav/1 returns tournaments which is filtered by favorite users for home screen" do
      user1 = fixture_user()
      tournament = fixture_tournament()
      {:ok, _} = Tournaments.update_tournament(tournament, @home_attrs)

      Relations.create_relation(%{
        "follower_id" => user1.id,
        "followee_id" => tournament.master_id
      })

      user1.id
      |> Tournaments.home_tournament_fav()
      |> length()
      |> then(fn len ->
        assert len == 1
      end)
    end

    test "home_tournament_fav/1 fails to return tournaments which is filtered by favorite users for home screen" do
      tournament = fixture_tournament()
      {:ok, _} = Tournaments.update_tournament(tournament, @home_attrs)

      tournament.master_id
      |> Tournaments.home_tournament_fav()
      |> Enum.empty?()
      |> assert()
    end

    test "home_tournament_plan/1 returns user's tournaments" do
      tournament = fixture_tournament()
      {:ok, _} = Tournaments.update_tournament(tournament, @home_attrs)

      tournament.master_id
      |> Tournaments.home_tournament_plan()
      |> Enum.empty?()
      |> refute()
    end

    test "home_tournament_plan/1 fails to return user's tournaments" do
      tournament = fixture_tournament(deadline: "2010-04-17T14:00:00Z", event_date: "2010-04-17T14:00:00Z")

      refute Tournaments.home_tournament_plan(tournament.master_id) == []
    end

    test "search/2 works" do
      user = fixture_user()

      tomorrow =
        Timex.now()
        |> Timex.add(Timex.Duration.from_days(1))
        |> Timex.to_datetime()

      yesterday =
        Timex.now()
        |> Timex.add(Timex.Duration.from_days(-1))
        |> Timex.to_datetime()

      @valid_attrs
      |> Map.put("deadline", tomorrow)
      |> Map.put("event_date", tomorrow)
      |> Map.put("is_started", false)
      |> Map.put("master_id", user.id)
      |> Tournaments.create_tournament()

      @valid_attrs
      |> Map.put("deadline", tomorrow)
      |> Map.put("event_date", tomorrow)
      |> Map.put("name", "favorite")
      |> Map.put("game_name", "favorite game")
      |> Map.put("master_id", user.id)
      |> Map.put("is_started", false)
      |> Tournaments.create_tournament()

      @valid_attrs
      |> Map.put("deadline", tomorrow)
      |> Map.put("event_date", tomorrow)
      |> Map.put("name", "test")
      |> Map.put("game_name", "test")
      |> Map.put("master_id", user.id)
      |> Map.put("is_started", false)
      |> Tournaments.create_tournament()

      @valid_attrs
      |> Map.put("deadline", yesterday)
      |> Map.put("event_date", yesterday)
      |> Map.put("name", "dummy test")
      |> Map.put("game_name", "dummy test")
      |> Map.put("master_id", user.id)
      |> Map.put("is_started", false)
      |> Tournaments.create_tournament()

      nil
      |> Tournaments.search("test")
      |> Enum.map(fn tournament ->
        assert tournament.name == "test"
      end)
      |> length()
      |> Kernel.==(1)
      |> assert()

      nil
      |> Tournaments.search("game")
      |> Enum.map(fn tournament ->
        assert tournament.name == "favorite" || tournament.name == "some name"
      end)
      |> length()
      |> Kernel.==(2)
      |> assert()

      nil
      |> Tournaments.search("fizz")
      |> Enum.empty?()
      |> assert()

      nil
      |> Tournaments.search("name")
      |> length()
      |> Kernel.==(1)
      |> assert()
    end
  end

  describe "get tournament by url" do
    test "get_tournament_by_url/1 works with valid data" do
      tournament = fixture_tournament()
      t = Tournaments.load_tournament_by_url(tournament.url)
      assert tournament.id == t.id
    end
  end

  describe "game" do
    test "get_tournament_by_game_id/1 returns game of the tournament" do
      game = fixture(:game)
      user = fixture_user()

      @valid_attrs
      |> Map.put("game_id", game.id)
      |> Map.put("master_id", user.id)
      |> Tournaments.create_tournament()

      assert %Tournament{} = Tournaments.get_tournament_by_game_id(game.id)
    end
  end

  describe "get entrant" do
    setup [:create_entrant]

    test "get_entrant/1 work with valid data", %{entrant: entrant} do
      assert %Entrant{} = obtained_entrant = Tournaments.get_entrant(entrant.id)
      assert obtained_entrant.id == entrant.id
    end

    test "get_entrants/1 works with valid data", %{entrant: entrant} do
      num = 7

      entrants =
        num
        |> create_entrants(entrant.tournament_id)
        |> Enum.concat([entrant])

      entrant.tournament_id
      |> Tournaments.get_entrants()
      |> Enum.map(fn entrant ->
        assert %Entrant{} = entrant
      end)
      |> length()
      |> then(fn len ->
        assert len == length(entrants)
      end)
    end

    test "get_entrants/1 returns data 1 size smaller than past one after deleting an entrant", %{
      entrant: entrant
    } do
      num = 7

      entrants =
        num
        |> create_entrants(entrant.tournament_id)
        |> Enum.concat([entrant])

      entrants
      |> hd()
      |> Map.get(:user_id)
      |> Accounts.get_user()
      |> Repo.delete()

      entrant.tournament_id
      |> Tournaments.get_entrants()
      |> Enum.map(fn entrant ->
        assert %Entrant{} = entrant
      end)
      |> length()
      |> then(fn len ->
        assert len == length(entrants) - 1
      end)
    end

    test "get_entrant_including_logs/1 gets tournament log with a valid data", %{entrant: entrant} do
      num = 7
      create_entrants(num, entrant.tournament_id)
      Tournaments.finish(entrant.tournament_id, entrant.id)

      assert %EntrantLog{} = Tournaments.get_entrant_including_logs(entrant.id)
    end

    test "get_entrant_including_logs/1 gets tournament with a valid data", %{entrant: entrant} do
      num = 7
      create_entrants(num, entrant.tournament_id)

      assert %Entrant{} = Tournaments.get_entrant_including_logs(entrant.id)
    end

    test "get_entrant_including_logs/1 does not work with an invalid data", %{entrant: _entrant} do
      assert nil == Tournaments.get_entrant_including_logs(-1)
    end
  end

  describe "is_participant?" do
    test "team works" do
      tournament = fixture_tournament(is_team: true, team_size: 2)

      # NOTE: 参加チームを作成し、テスト用のユーザーを一人取り出す。
      tournament.id
      |> fill_with_team()
      |> Enum.map(fn team ->
        team.id
        |> Tournaments.get_leader()
        |> Map.get(:user)
      end)
      |> hd()
      ~> user

      assert Tournaments.is_participant?(tournament.id, user.id)

      invalid_user = fixture_user(num: 200)

      refute Tournaments.is_participant?(tournament.id, invalid_user.id)
    end

    test "individual works" do
      tournament = fixture_tournament(capacity: 2)

      tournament.id
      |> fill_with_entrant()
      |> hd()
      |> Map.get(:user_id)
      ~> user_id

      assert Tournaments.is_participant?(tournament.id, user_id)

      invalid_user = fixture_user(num: 200)

      refute Tournaments.is_participant?(tournament.id, invalid_user.id)
    end
  end

  describe "create entrant" do
    test "create_entrant/1 with a valid data works fine" do
      user = fixture_user()
      tournament = fixture_tournament()

      {:ok, entrant} =
        @entrant_create_attrs
        |> Map.put("tournament_id", tournament.id)
        |> Map.put("user_id", user.id)
        |> Tournaments.create_entrant()

      assert entrant.user_id == user.id
    end

    test "create_entrant/1 with an invalid data does not work" do
      assert {:error, _} = Tournaments.create_entrant(@invalid_entrant_create_attrs)
    end

    test "create_entrant/1 returns an error when entrant already exists" do
      user = fixture_user()
      tournament = fixture_tournament()

      entrant_params =
        @entrant_create_attrs
        |> Map.put("tournament_id", tournament.id)
        |> Map.put("user_id", user.id)

      Tournaments.create_entrant(entrant_params)

      assert {:error, "already joined"} = Tournaments.create_entrant(entrant_params)
    end

    test "create_entrant/1 returns a team error when the tournament requires team participation" do
      user = fixture_user()
      tournament = fixture_tournament(is_team: true)

      entrant_params =
        @entrant_create_attrs
        |> Map.put("tournament_id", tournament.id)
        |> Map.put("user_id", user.id)

      assert {:error, "requires team"} = Tournaments.create_entrant(entrant_params)
    end

    test "create_entrant/1 returns a multi error when it runs with same parameter at one time." do
      # tournament and user for entrant_param
      user0 = fixture_user()
      user1 = fixture_user(num: 2)
      tournament0 = fixture_tournament()
      tournament1 = fixture_tournament(master_id: user1.id)

      entrant_param =
        @entrant_create_attrs
        |> Map.put("tournament_id", tournament0.id)
        |> Map.put("user_id", user0.id)

      # entrant作成の並行タスク生成
      create_entrant_task0 = Task.async(fn -> Tournaments.create_entrant(entrant_param) end)

      create_entrant_task1 =
        Task.async(fn ->
          Tournaments.create_entrant(%{entrant_param | "tournament_id" => tournament1.id})
        end)

      create_entrant_task2 = Task.async(fn -> Tournaments.create_entrant(entrant_param) end)

      # 元のパラメータとそれぞれtournament_id, user_idのどちらかの重複，どちらも同じの合計4パターンのentrant作成結果の出力
      # 元のentrant_param
      assert {:ok, _} = Task.await(create_entrant_task0)
      # user_idのみ書き換えたパラメータ
      assert {:ok, _} = Tournaments.create_entrant(%{entrant_param | "user_id" => user1.id})
      # tournament_idのみ書き換えたパラメータ
      assert {:ok, _} = Task.await(create_entrant_task1)
      # どちらも書き換えていないパラメータ
      assert {:error, _} = Task.await(create_entrant_task2)
    end
  end

  describe "update entrant" do
    setup [:create_entrant]

    test "update_entrant/2 works fine with a valid data", %{entrant: entrant} do
      update_attrs = %{"rank" => 1}
      assert {:ok, _entrant} = Tournaments.update_entrant(entrant, update_attrs)
    end
  end

  describe "delete loser" do
    test "delete_loser/2 works fine with a valid data of 4 players" do
      list = [[1, 2], [3, 4]]
      assert Tournaments.delete_loser(list, 1) == [2, [3, 4]]
      assert Tournaments.delete_loser(list, [1]) == [2, [3, 4]]
      assert Tournaments.delete_loser(list, 2) == [1, [3, 4]]
      assert Tournaments.delete_loser(list, [2]) == [1, [3, 4]]
      assert Tournaments.delete_loser(list, 3) == [[1, 2], 4]
      assert Tournaments.delete_loser(list, [3]) == [[1, 2], 4]
      assert Tournaments.delete_loser(list, 4) == [[1, 2], 3]
      assert Tournaments.delete_loser(list, [4]) == [[1, 2], 3]
    end

    test "delete_loser/2 works fine with a valid data of 3 players" do
      list = [[1, 2], 3]

      assert Tournaments.delete_loser(list, 1) == [2, 3]
      assert Tournaments.delete_loser(list, [1]) == [2, 3]
      assert Tournaments.delete_loser(list, 2) == [1, 3]
      assert Tournaments.delete_loser(list, [2]) == [1, 3]
      assert Tournaments.delete_loser(list, 3) == [1, 2]
      assert Tournaments.delete_loser(list, [3]) == [1, 2]
    end

    test "delete_loser/2 works fine with a valid data of 5 players" do
      list = [[1, 2], [[3, 4], 5]]

      assert Tournaments.delete_loser(list, 1) == [2, [[3, 4], 5]]
      assert Tournaments.delete_loser(list, [1]) == [2, [[3, 4], 5]]
      assert Tournaments.delete_loser(list, 2) == [1, [[3, 4], 5]]
      assert Tournaments.delete_loser(list, [2]) == [1, [[3, 4], 5]]
      assert Tournaments.delete_loser(list, 3) == [[1, 2], [4, 5]]
      assert Tournaments.delete_loser(list, [3]) == [[1, 2], [4, 5]]
      assert Tournaments.delete_loser(list, 4) == [[1, 2], [3, 5]]
      assert Tournaments.delete_loser(list, [4]) == [[1, 2], [3, 5]]
      assert Tournaments.delete_loser(list, 5) == [[1, 2], [3, 4]]
      assert Tournaments.delete_loser(list, [5]) == [[1, 2], [3, 4]]
    end

    test "delete_loser/2 does not work with an invalid data of 3 players" do
      list = [1, 2, 3]

      assert catch_error(Tournaments.delete_loser(list, 1)) == %RuntimeError{
               message: "Bad Argument"
             }
    end

    test "delete_loser/2 does not work with an invalid data of 1 player" do
      list = [1]

      assert Tournaments.delete_loser(list, 1) == []
    end
  end

  describe "tournament flow functions" do
    setup [:create_tournament_for_flow]

    test "start/2 with valid data works fine", %{tournament: tournament} do
      fixture_entrant(%{"tournament_id" => tournament.id})
      user = fixture_user()
      fixture_entrant(%{"tournament_id" => tournament.id, "user_id" => user.id})
      assert {:ok, _tournament} = Tournaments.start(tournament.id, tournament.master_id)

      assert {:error, "tournament is already started"} ==
               Tournaments.start(tournament.id, tournament.master_id)
    end

    test "start/2 with only one entrant returns too few entrants error.", %{
      tournament: tournament
    } do
      assert {:error, "short of participants"} ==
               Tournaments.start(tournament.id, tournament.master_id)
    end

    test "start/2 with nil returns master_id or tournament_id is nil error", %{
      tournament: _tournament
    } do
      assert {:error, "master_id or tournament_id is nil"} == Tournaments.start(nil, nil)
      assert {:error, "master_id or tournament_id is nil"} == Tournaments.start(1, nil)
      assert {:error, "master_id or tournament_id is nil"} == Tournaments.start(nil, 1)
    end

    test "generate_matchlist/1 with valid data works fine", %{tournament: _tournament} do
      data = [1, 2, 3, 4, 5, 6]
      assert {:ok, matchlist} = Tournaments.generate_matchlist(data)
      assert is_list(matchlist)
    end

    test "generate_matchlist/1 with invalid integer data does not work", %{
      tournament: _tournament
    } do
      data = 1
      assert {:error, _} = Tournaments.generate_matchlist(data)
    end

    test "generate_matchlist/1 with invalid map data does not work", %{tournament: _tournament} do
      data = %{a: 1, b: 2, c: 3}
      assert {:error, _} = Tournaments.generate_matchlist(data)
    end

    test "find_match/3 with valid data works fine" do
      data = [1, 2, 3, 4, 5, 6]
      {:ok, matchlist} = Tournaments.generate_matchlist(data)
      assert match = Tournaments.find_match(matchlist, 1)
      assert is_list(match)
    end

    test "find_match/3 with invalid data does not work" do
      invalid_data = 3
      assert Tournaments.find_match(invalid_data, 3) == []
    end

    test "is_alone?/1 works fine with valid data" do
      list = [1, 2]
      refute Tournaments.is_alone?(list)
      list = [1, [2, 3]]
      assert Tournaments.is_alone?(list)
    end

    test "finish/2 works fine with valid data" do
      user = fixture_user()

      {:ok, tournament} =
        @valid_attrs
        |> Map.put("master_id", user.id)
        |> Tournaments.create_tournament()

      assert Tournaments.finish(tournament.id, user.id)
    end
  end

  describe "get entrant's rank" do
    setup [:create_entrant]

    test "get_rank/2 returns entrant's rank when data is valid", %{entrant: entrant} do
      assert Tournaments.get_rank(entrant.tournament_id, entrant.user_id) == {:ok, entrant.rank}
    end

    test "get_rank/2 returns error with invalid tournament_id", %{entrant: entrant} do
      assert Tournaments.get_rank(-1, entrant.user_id) == {:error, "entrant is not found"}
    end

    test "get_rank/2 returns error with invalid user_id", %{entrant: entrant} do
      assert Tournaments.get_rank(entrant.tournament_id, -1) == {:error, "entrant is not found"}
    end

    test "get_rank/2 returns error with invalid params" do
      assert Tournaments.get_rank(-1, -1) == {:error, "entrant is not found"}
    end
  end

  defp start(master_id, tournament_id) do
    Tournaments.start(tournament_id, master_id)

    {:ok, match_list} =
      Tournaments.get_entrants(tournament_id)
      |> Enum.map(fn x -> x.user_id end)
      |> Tournaments.generate_matchlist()

    count =
      Tournaments.load_tournament(tournament_id)
      |> Map.get(:count)

    match_list
    |> Tournaments.initialize_rank(count, tournament_id)

    match_list
    |> Progress.insert_match_list(tournament_id)

    list_with_fight_result =
      match_list
      |> match_list_with_fight_result()

    lis =
      list_with_fight_result
      |> List.flatten()

    Enum.reduce(lis, list_with_fight_result, fn x, acc ->
      user = Accounts.get_user(x["user_id"])

      acc
      |> Tournaments.put_value_on_brackets(user.id, %{"name" => user.name})
      |> Tournaments.put_value_on_brackets(user.id, %{"win_count" => 0})
      |> Tournaments.put_value_on_brackets(user.id, %{"icon_path" => user.icon_path})
    end)
    |> Progress.insert_match_list_with_fight_result(tournament_id)
  end

  defp match_list_with_fight_result(match_list) do
    Tournaments.initialize_match_list_with_fight_result(match_list)
  end

  defp create_tournament_for_flow(_) do
    tournament = fixture_tournament(is_started: false)
    %{tournament: tournament}
  end

  defp create_entrants(num, tournament_id, result \\ []),
    do: create_entrants(num, tournament_id, result, num)

  defp create_entrants(_num, _tournament_id, result, 0) do
    result
  end

  defp create_entrants(num, tournament_id, result, current) do
    {:ok, user} =
      %{
        "name" => "name" <> to_string(current),
        "email" => "e" <> to_string(current) <> "@mail.com",
        "password" => "Password123"
      }
      |> Accounts.create_user()

    {:ok, entrant} =
      %{
        @entrant_create_attrs
        | "tournament_id" => tournament_id,
          "user_id" => user.id,
          "rank" => num
      }
      |> Tournaments.create_entrant()

    create_entrants(num, tournament_id, result ++ [entrant], current - 1)
  end

  defp create_entrant(_) do
    entrant = fixture_entrant()
    %{entrant: entrant}
  end

  describe "get assistant" do
    test "get_assistants/1 works" do
      assistant_attr = fixture(:assistant)

      assistant_attr["tournament_id"]
      |> Tournaments.get_assistants()
      |> Enum.map(fn assistant ->
        assert assistant.user_id == hd(assistant_attr["user_id"])
        assert assistant.tournament_id == assistant_attr["tournament_id"]
        assistant = Tournaments.get_assistant(assistant.id)
        assert assistant.user_id == hd(assistant_attr["user_id"])
        assert assistant.tournament_id == assistant_attr["tournament_id"]
      end)
      |> length()
      |> then(fn len ->
          assert len == 1
        end)
    end

    test "get_assistants_by_user_id/1" do
      assistant_attr = fixture(:assistant)

      assistant_attr["user_id"]
      |> hd()
      |> Tournaments.get_assistants_by_user_id()
      |> Enum.map(fn assistant ->
        assert assistant.user_id == hd(assistant_attr["user_id"])
        assert assistant.tournament_id == assistant_attr["tournament_id"]
      end)
      |> length()
      |> then(fn len ->
          assert len == 1
        end)
    end
  end

  describe "create assistants" do
    test "create_assistants/1 with valid data works fine" do
      assert fixture(:assistant)
    end
  end

  describe "get tournament chat topic" do
    test "get_tournament_chat_topic!/1 with valid data works fine" do
      topic = fixture(:tournament_chat_topic)

      assert %TournamentChatTopic{} = obtained_topic = Tournaments.get_tournament_chat_topic!(topic.id)

      assert obtained_topic.id == topic.id
      assert obtained_topic.topic_name == topic.topic_name
    end

    test "get_tabs_including_logs_by_tourament_id/1 with valid data works fine" do
      topic = fixture(:tournament_chat_topic)
      tabs = Tournaments.get_tabs_including_logs_by_tourament_id(topic.tournament_id)
      assert is_list(tabs)
      refute Enum.empty?(tabs)

      Enum.each(tabs, fn tab ->
        assert %TournamentChatTopic{} = tab
        assert tab.tournament_id == topic.tournament_id
      end)
    end
  end

  describe "create tournament chat topic" do
    test "create_tournament_chat_topic/1 works fine with a valid data" do
      assert %TournamentChatTopic{} = fixture(:tournament_chat_topic)
    end
  end

  describe "update tournament chat topic" do
    test "update_tournament_chat_topic/1 works fine with a valid data" do
      topic = fixture(:tournament_chat_topic)
      attrs = %{"topic_name" => "updated name"}
      assert {:ok, updated_topic} = Tournaments.update_tournament_chat_topic(topic, attrs)
      assert updated_topic.topic_name == attrs["topic_name"]
    end
  end

  describe "delete tournament chat topic" do
    test "delete_tournament_chat_topic/1 works fine with a valid data" do
      topic = fixture(:tournament_chat_topic)
      assert {:ok, deleted_topic} = Tournaments.delete_tournament_chat_topic(topic)
      assert deleted_topic.id == topic.id

      assert %Ecto.NoResultsError{} = catch_error(Tournaments.get_tournament_chat_topic!(deleted_topic.id))
    end
  end

  describe "initialize rank" do
    test "initialize_rank works fine with valid data" do
      tournament = fixture_tournament()
      entrants = create_entrants(6, tournament.id)
      id_list = Enum.map(entrants, fn entrant -> entrant.user_id end)
      {:ok, match_list} = Tournaments.generate_matchlist(id_list)

      ranked_entrants = Tournaments.initialize_rank(match_list, 6, tournament.id)
      assert is_list(ranked_entrants)
      refute Enum.empty?(ranked_entrants)
    end
  end

  describe "has_lost?" do
    setup [:create_entrant]

    test "has_lost?/3 returns true with a lost match list", %{entrant: entrant} do
      num = 7

      {_, match_list} =
        create_entrants(num, entrant.tournament_id)
        |> Enum.map(fn x -> %{x | rank: num + 1} end)
        |> Kernel.++([%{entrant | rank: num + 1}])
        |> Enum.map(fn entrant -> entrant.user_id end)
        |> Tournaments.generate_matchlist()

      match_list = Tournaments.delete_loser(match_list, entrant.user_id)
      assert Tournaments.has_lost?(match_list, entrant.user_id)
    end

    test "has_lost?/3 returns false with a just generated match list", %{entrant: entrant} do
      num = 7

      {_, match_list} =
        create_entrants(num, entrant.tournament_id)
        |> Enum.map(fn x -> %{x | rank: num + 1} end)
        |> Kernel.++([%{entrant | rank: num + 1}])
        |> Enum.map(fn entrant -> entrant.user_id end)
        |> Tournaments.generate_matchlist()

      refute Tournaments.has_lost?(match_list, entrant.user_id)
    end
  end

  describe "promote rank" do
    setup [:create_entrant]

    test "promote_rank/1 returns promoted rank with valid attrs", %{entrant: entrant} do
      attrs = %{
        "tournament_id" => entrant.tournament_id,
        "user_id" => entrant.user_id
      }

      # numは生成する参加者の数で後に一人追加するので8 - 1 = 7
      num = 7
      # 参加者作成，マッチリストを生成してProgressに登録
      num
      |> create_entrants(entrant.tournament_id)
      |> Enum.map(fn x -> %{x | rank: num + 1} end)
      |> Kernel.++([%{entrant | rank: num + 1}])
      |> Enum.map(fn entrant -> entrant.user_id end)
      |> Tournaments.generate_matchlist()
      ~> {_, match_list}

      Progress.insert_match_list(match_list, entrant.tournament_id)

      assert {:ok, _} = Tournaments.promote_rank(attrs)
    end

    test "promote_rank/1 returns error with invalid attrs(tournament_id)", %{entrant: entrant} do
      # promote_rankの引数となるattrs
      attrs = %{
        "tournament_id" => -1,
        "user_id" => entrant.user_id
      }

      # numは生成する参加者の数で後に一人追加するので8 - 1 = 7
      num = 7
      # 参加者作成，マッチリストを生成してProgressに登録
      create_entrants(num, entrant.tournament_id)
      |> Enum.map(fn x -> %{x | rank: num + 1} end)
      |> Kernel.++([%{entrant | rank: num + 1}])
      |> Tournaments.generate_matchlist()
      |> Progress.insert_match_list(entrant.tournament_id)

      assert {:error, "undefined tournament"} = Tournaments.promote_rank(attrs)
    end

    test "promote_rank/1 returns error with invalid attrs(user_id)", %{entrant: entrant} do
      # promote_rankの引数となるattrs
      attrs = %{
        "tournament_id" => entrant.tournament_id,
        "user_id" => -1
      }

      # numは生成する参加者の数で後に一人追加するので8 - 1 = 7
      num = 7
      # 参加者作成，マッチリストを生成してProgressに登録
      create_entrants(num, entrant.tournament_id)
      |> Enum.map(fn x -> %{x | rank: num + 1} end)
      |> Kernel.++([%{entrant | rank: num + 1}])
      |> Tournaments.generate_matchlist()
      |> Progress.insert_match_list(entrant.tournament_id)

      assert {:error, "undefined user"} = Tournaments.promote_rank(attrs)
    end

    test "promote_rank/1 returns error with invalid attrs(all)", %{entrant: entrant} do
      # promote_rankの引数となるattrs
      attrs = %{
        "tournament_id" => -1,
        "user_id" => -1
      }

      # numは生成する参加者の数で後に一人追加するので8 - 1 = 7
      num = 7
      # 参加者作成，マッチリストを生成してProgressに登録
      create_entrants(num, entrant.tournament_id)
      |> Enum.map(fn x -> %{x | rank: num + 1} end)
      |> Kernel.++([%{entrant | rank: num + 1}])
      |> Tournaments.generate_matchlist()
      |> Progress.insert_match_list(entrant.tournament_id)

      assert {:error, "undefined user"} = Tournaments.promote_rank(attrs)
    end

    test "run promote_rank/1 in a row with 8 entrants", %{entrant: entrant} do
      attrs = %{
        "tournament_id" => entrant.tournament_id,
        "user_id" => entrant.user_id
      }

      # numは生成する参加者の数で後に一人追加するので8 - 1 = 7
      num = 7
      # 参加者作成，マッチリストを生成してProgressに登録
      {:ok, match_list} =
        create_entrants(num, entrant.tournament_id)
        |> Enum.map(fn x -> %{x | rank: num + 1} end)
        |> Kernel.++([%{entrant | rank: num + 1}])
        |> Enum.map(fn entrant -> entrant.user_id end)
        |> Tournaments.generate_matchlist()

      Progress.insert_match_list(match_list, entrant.tournament_id)

      assert {:ok, _promoted} = Tournaments.promote_rank(attrs)
      assert Tournaments.get_rank(entrant.tournament_id, entrant.user_id) == {:ok, 4}

      {:ok, opponent} = Tournaments.get_opponent(entrant.tournament_id, entrant.user_id)

      Progress.delete_match_list(entrant.tournament_id)
      updated = Tournaments.delete_loser(match_list, opponent.id)

      Progress.insert_match_list(updated, entrant.tournament_id)

      assert {:wait, nil} = Tournaments.promote_rank(attrs)
    end

    test "run promote_rank/1 in a row with 4 entrants", %{entrant: entrant} do
      attrs = %{
        "tournament_id" => entrant.tournament_id,
        "user_id" => entrant.user_id
      }

      num = 3

      {:ok, match_list} =
        create_entrants(num, entrant.tournament_id)
        |> Enum.map(fn x -> %{x | rank: num + 1} end)
        |> Kernel.++([%{entrant | rank: num + 1}])
        |> Enum.map(fn entrant -> entrant.user_id end)
        |> Tournaments.generate_matchlist()

      Progress.insert_match_list(match_list, entrant.tournament_id)

      assert {:ok, _promoted} = Tournaments.promote_rank(attrs)
      assert Tournaments.get_rank(entrant.tournament_id, entrant.user_id) == {:ok, 2}

      {:ok, opponent} = Tournaments.get_opponent(entrant.tournament_id, entrant.user_id)

      Progress.delete_match_list(entrant.tournament_id)
      updated = Tournaments.delete_loser(match_list, opponent.id)

      Progress.insert_match_list(updated, entrant.tournament_id)

      assert {:wait, nil} = Tournaments.promote_rank(attrs)
    end

    test "run promote_rank/1 in a row with 2 entrants", %{entrant: entrant} do
      attrs = %{
        "tournament_id" => entrant.tournament_id,
        "user_id" => entrant.user_id
      }

      num = 1

      num
      |> create_entrants(entrant.tournament_id)
      |> Enum.map(fn x -> %{x | rank: num + 1} end)
      |> Kernel.++([%{entrant | rank: num + 1}])
      |> Enum.map(fn entrant -> entrant.user_id end)
      |> Tournaments.generate_matchlist()
      ~> {:ok, match_list}

      Progress.insert_match_list(match_list, entrant.tournament_id)

      assert {:ok, _promoted} = Tournaments.promote_rank(attrs)
      assert Tournaments.get_rank(entrant.tournament_id, entrant.user_id) == {:ok, 1}

      {:ok, opponent} = Tournaments.get_opponent(entrant.tournament_id, entrant.user_id)

      Progress.delete_match_list(entrant.tournament_id)
      updated = Tournaments.delete_loser(match_list, opponent.id)

      Progress.insert_match_list(updated, entrant.tournament_id)
    end
  end

  describe "promote rank(team) and initialize rank(team)" do
    defp claim_score(team_id, opponent_team_id, score, match_index) do
      team_id
      |> Tournaments.get_team()
      |> Map.get(:tournament_id)
      ~> tournament_id

      Progress.insert_score(tournament_id, team_id, score)

      tournament_id
      |> Progress.get_score(opponent_team_id)
      |> case do
        n when is_integer(n) ->
          cond do
            n > score ->
              Tournaments.delete_loser_process(tournament_id, [team_id])
              Tournaments.store_score(tournament_id, opponent_team_id, team_id, n, score, match_index)
              Progress.delete_match_pending_list(team_id, tournament_id)
              Progress.delete_match_pending_list(opponent_team_id, tournament_id)
              Progress.delete_score(tournament_id, team_id)
              Progress.delete_score(tournament_id, opponent_team_id)
              finish_as_needed(tournament_id, opponent_team_id)
              %{validated: true, completed: true}

            n < score ->
              Tournaments.delete_loser_process(tournament_id, [opponent_team_id])
              Tournaments.store_score(tournament_id, team_id, opponent_team_id, score, n, match_index)
              Progress.delete_match_pending_list(team_id, tournament_id)
              Progress.delete_score(tournament_id, team_id)
              Progress.delete_score(tournament_id, opponent_team_id)
              finish_as_needed(tournament_id, opponent_team_id)
              %{validated: true, completed: true}

            true ->
              %{validated: false, completed: true}
          end

        nil ->
          %{validated: true, completed: false}
      end
    end

    defp finish_as_needed(tournament_id, winner_id) do
      match_list = Progress.get_match_list(tournament_id)

      if is_integer(match_list) do
        Tournaments.finish(tournament_id, winner_id)

        tournament_id
        |> Progress.get_match_list_with_fight_result()
        |> inspect(charlists: false)
        |> (fn str ->
              %{"tournament_id" => tournament_id, "match_list_with_fight_result_str" => str}
            end).()
        |> Progress.create_match_list_with_fight_result_log()

        Progress.delete_match_list(tournament_id)
        Progress.delete_match_list_with_fight_result(tournament_id)
        Progress.delete_match_pending_list_of_tournament(tournament_id)
        Progress.delete_fight_result_of_tournament(tournament_id)
        Progress.delete_duplicate_users_all(tournament_id)
      end

      if match_list == [] do
        Logger.error("Match list error on finish as needed")
      end
    end

    test "promote_rank/1 returns promoted rank with valid attrs" do
      [is_team: true, capacity: 4, type: 2]
      |> fixture_tournament()
      ~> tournament
      |> Map.get(:id)
      |> fill_with_team()
      ~> teams
      |> Enum.map(fn team ->
        team.id
        |> Tournaments.get_leader()
        |> Map.get(:user)
      end)
      ~> leaders

      # assert用のidリスト作成
      teams
      |> Enum.map(fn team ->
        team.id
      end)
      ~> team_id_list

      # assert用の名前リスト作成
      leaders
      |> Enum.map(fn leader ->
        leader.name
      end)
      ~> leader_name_list

      # assert用のアイコンパスリスト作成
      leaders
      |> Enum.map(fn leader ->
        leader.icon_path
      end)
      ~> leader_icon_path_list

      tournament
      |> Progress.start_team_flipban()
      ~> {:ok, match_list, _}

      # match_listの初期状態確認
      tournament.id
      |> Progress.get_match_list()
      |> Kernel.==(match_list)
      |> assert()

      # match_list_with_fight_resultの初期状態確認
      tournament.id
      |> Progress.get_match_list_with_fight_result()
      |> List.flatten()
      |> Enum.map(fn cell ->
        assert cell["name"] in leader_name_list
        assert cell["icon_path"] in leader_icon_path_list
        assert cell["win_count"] == 0
        assert cell["round"] == 0
        refute cell["is_loser"]
      end)
      |> length()
      |> Kernel.==(4)
      |> assert()

      # 初期ランク確認
      tournament.id
      |> Tournaments.get_confirmed_teams()
      |> Enum.each(fn team ->
        assert team.rank == 4
      end)

      your_team = hd(teams)
      your_score = 300
      opponent_score = 15

      your_leader = Tournaments.get_leader(your_team.id)

      tournament.id
      |> Tournaments.get_opponent(your_leader.user_id)
      ~> {:ok, opponent_team}

      result = claim_score(your_team.id, opponent_team.id, your_score, 0)
      assert result.validated
      refute result.completed

      result = claim_score(opponent_team.id, your_team.id, opponent_score, 0)
      assert result.validated
      assert result.validated

      # NOTE: match_listの状態確認
      tournament.id
      |> Progress.get_match_list()
      |> List.flatten()
      |> Enum.map(fn cell ->
        refute cell == opponent_team.id
        assert cell in team_id_list
      end)
      |> length()
      |> Kernel.==(3)
      |> assert()

      # NOTE: match_list_with_fight_resultの状態確認
      tournament.id
      |> Progress.get_match_list_with_fight_result()
      |> List.flatten()
      |> Enum.map(fn cell ->
        assert cell["name"] in leader_name_list
        assert cell["icon_path"] in leader_icon_path_list
        # HACK: ここのroundはゼロでいいのかちょっとわからない
        assert cell["round"] == 0

        if cell["team_id"] == opponent_team.id do
          assert cell["is_loser"]
        else
          refute cell["is_loser"]
        end

        if cell["team_id"] == your_team.id do
          assert cell["win_count"] == 1
        else
          assert cell["win_count"] == 0
        end
      end)
      |> length()
      |> Kernel.==(4)
      |> assert()

      # NOTE: ランク確認
      tournament.id
      |> Tournaments.get_confirmed_teams()
      |> Enum.each(fn team ->
        if team.id == your_team.id do
          assert team.rank == 2
        else
          assert team.rank == 4
        end
      end)

      # NOTE: 反対側のブロックのマッチを取得
      tournament.id
      |> Progress.get_match_list()
      |> Enum.filter(fn match_or_id ->
        match_or_id != your_team.id
      end)
      |> hd()
      |> Enum.map(fn id ->
        Tournaments.get_team(id)
      end)
      ~> opposite_side_teams

      another_team = hd(opposite_side_teams)
      another_score = 200
      another_opponent_score = 10

      another_team_leader = Tournaments.get_leader(another_team.id)

      tournament.id
      |> Tournaments.get_opponent(another_team_leader.user_id)
      ~> {:ok, another_opponent_team}

      # NOTE: 勝敗報告
      result = claim_score(another_team.id, another_opponent_team.id, another_score, 0)
      assert result.validated
      refute result.completed

      result = claim_score(another_opponent_team.id, another_team.id, another_opponent_score, 0)

      assert result.validated
      assert result.validated

      # NOTE: match_listの状態確認
      tournament.id
      |> Progress.get_match_list()
      |> Enum.map(fn cell ->
        assert cell == your_team.id || cell == another_team.id
      end)
      |> length()
      |> Kernel.==(2)
      |> assert()

      # NOTE: match_list_with_fight_resultの状態確認
      tournament.id
      |> Progress.get_match_list_with_fight_result()
      |> List.flatten()
      |> Enum.map(fn cell ->
        assert cell["name"] in leader_name_list
        assert cell["icon_path"] in leader_icon_path_list
        assert cell["round"] == 0

        cond do
          cell["team_id"] == your_team.id ->
            refute cell["is_loser"]
            assert cell["win_count"] == 1

          cell["team_id"] == another_team.id ->
            refute cell["is_loser"]
            assert cell["win_count"] == 1

          true ->
            assert cell["is_loser"]
            assert cell["win_count"] == 0
        end
      end)
      |> length()
      |> Kernel.==(4)
      |> assert()

      # NOTE: ランク確認
      tournament.id
      |> Tournaments.get_confirmed_teams()
      |> Enum.each(fn team ->
        cond do
          team.id == your_team.id ->
            assert team.rank == 2

          team.id == another_team.id ->
            assert team.rank == 2

          true ->
            assert team.rank == 4
        end
      end)

      result = claim_score(your_team.id, another_team.id, your_score, 0)
      assert result.validated
      refute result.completed

      result = claim_score(another_team.id, your_team.id, another_score, 0)
      assert result.validated
      assert result.validated

      # match_listの最終状態確認
      tournament.id
      |> Progress.get_match_list()
      |> is_nil()
      |> assert()

      # match_list_with_fight_resultの最終状態確認
      tournament.id
      |> Progress.get_match_list_with_fight_result()
      |> is_nil()
      |> assert()

      # tournamentがlogになってるか確認
      assert {:ok, %TournamentLog{}} = Tournaments.get_tournament_including_logs(tournament.id)
    end
  end

  describe "data for brackets" do
    test "data_for_brackets/1 works fine with valid list data of size 3" do
      match_list = [3, [1, 2]]
      assert Tournaments.data_for_brackets(match_list) == [[2, 1], [nil, 3]]
    end

    test "data_for_brackets/1 works fine with valid list data of size 4" do
      match_list = [[1, 2], [3, 4]]
      assert Tournaments.data_for_brackets(match_list) == [[4, 3], [2, 1]]
    end

    test "data_for_brackets/1 works fine with valid list data of size 5" do
      match_list = [[1, 2], [3, [4, 5]]]
      assert Tournaments.data_for_brackets(match_list) == [[5, 4], [nil, 3], [2, 1]]
    end

    test "data_for_brackets/1 works fine with valid list data of size 6" do
      match_list = [[1, [2, 3]], [4, [5, 6]]]
      assert Tournaments.data_for_brackets(match_list) == [[6, 5], [nil, 4], [3, 2], [nil, 1]]
    end

    test "data_for_brackets/1 works fine with valid list data of size 7" do
      match_list = [[1, [2, 3]], [[4, 5], [6, 7]]]
      assert Tournaments.data_for_brackets(match_list) == [[7, 6], [5, 4], [3, 2], [nil, 1]]
    end

    test "data_for_brackets/1 works fine with valid list data of size 8" do
      match_list = [[[1, 2], [3, 4]], [[5, 6], [7, 8]]]
      assert Tournaments.data_for_brackets(match_list) == [[8, 7], [6, 5], [4, 3], [2, 1]]
    end

    test "data_for_brackets/1 works fine with valid list data of size 9" do
      match_list = [[[1, 2], [3, 4]], [[5, 6], [7, [8, 9]]]]

      assert Tournaments.data_for_brackets(match_list) == [
               [9, 8],
               [nil, 7],
               [6, 5],
               [4, 3],
               [2, 1]
             ]
    end
  end

  describe "data with fight result for brackets" do
    test "data_with_fight_result_for_brackets/1 works fine with valid list data of size 3" do
      match_list = [
        %{"user_id" => 3, "is_loser" => false, "name" => "testname", "win_count" => 0},
        [
          %{"user_id" => 1, "is_loser" => false, "name" => "testname", "win_count" => 0},
          %{"user_id" => 2, "is_loser" => false, "name" => "testname", "win_count" => 0}
        ]
      ]

      assert Tournaments.data_with_fight_result_for_brackets(match_list) == [
               [
                 %{"user_id" => 2, "is_loser" => false, "name" => "testname", "win_count" => 0},
                 %{"user_id" => 1, "is_loser" => false, "name" => "testname", "win_count" => 0}
               ],
               [
                 nil,
                 %{"user_id" => 3, "is_loser" => false, "name" => "testname", "win_count" => 0}
               ]
             ]
    end

    test "data_with_fight_result_for_brackets/1 works fine with valid list data of size 4" do
      match_list = [
        [
          %{"user_id" => 1, "is_loser" => false, "name" => "testname", "win_count" => 0},
          %{"user_id" => 2, "is_loser" => false, "name" => "testname", "win_count" => 0}
        ],
        [
          %{"user_id" => 3, "is_loser" => false, "name" => "testname", "win_count" => 0},
          %{"user_id" => 4, "is_loser" => false, "name" => "testname", "win_count" => 0}
        ]
      ]

      assert Tournaments.data_with_fight_result_for_brackets(match_list) == [
               [
                 %{"user_id" => 4, "is_loser" => false, "name" => "testname", "win_count" => 0},
                 %{"user_id" => 3, "is_loser" => false, "name" => "testname", "win_count" => 0}
               ],
               [
                 %{"user_id" => 2, "is_loser" => false, "name" => "testname", "win_count" => 0},
                 %{"user_id" => 1, "is_loser" => false, "name" => "testname", "win_count" => 0}
               ]
             ]
    end

    test "data_with_fight_result_for_brackets/1 works fine with valid list data of size 5" do
      match_list = [
        [
          %{"user_id" => 1, "is_loser" => false, "name" => "testname", "win_count" => 0},
          %{"user_id" => 2, "is_loser" => false, "name" => "testname", "win_count" => 0}
        ],
        [
          %{"user_id" => 3, "is_loser" => false, "name" => "testname", "win_count" => 0},
          [
            %{"user_id" => 4, "is_loser" => false, "name" => "testname", "win_count" => 0},
            %{"user_id" => 5, "is_loser" => false, "name" => "testname", "win_count" => 0}
          ]
        ]
      ]

      assert Tournaments.data_with_fight_result_for_brackets(match_list) == [
               [
                 %{"user_id" => 5, "is_loser" => false, "name" => "testname", "win_count" => 0},
                 %{"user_id" => 4, "is_loser" => false, "name" => "testname", "win_count" => 0}
               ],
               [
                 nil,
                 %{"user_id" => 3, "is_loser" => false, "name" => "testname", "win_count" => 0}
               ],
               [
                 %{"user_id" => 2, "is_loser" => false, "name" => "testname", "win_count" => 0},
                 %{"user_id" => 1, "is_loser" => false, "name" => "testname", "win_count" => 0}
               ]
             ]
    end

    test "data_with_fight_result_for_brackets/1 works fine with valid list data of size 6" do
      match_list = [
        [
          %{"user_id" => 1, "is_loser" => false, "name" => "testname", "win_count" => 0},
          [
            %{"user_id" => 2, "is_loser" => false, "name" => "testname", "win_count" => 0},
            %{"user_id" => 3, "is_loser" => false, "name" => "testname", "win_count" => 0}
          ]
        ],
        [
          %{"user_id" => 4, "is_loser" => false, "name" => "testname", "win_count" => 0},
          [
            %{"user_id" => 5, "is_loser" => false, "name" => "testname", "win_count" => 0},
            %{"user_id" => 6, "is_loser" => false, "name" => "testname", "win_count" => 0}
          ]
        ]
      ]

      assert Tournaments.data_with_fight_result_for_brackets(match_list) == [
               [
                 %{"user_id" => 6, "is_loser" => false, "name" => "testname", "win_count" => 0},
                 %{"user_id" => 5, "is_loser" => false, "name" => "testname", "win_count" => 0}
               ],
               [
                 nil,
                 %{"user_id" => 4, "is_loser" => false, "name" => "testname", "win_count" => 0}
               ],
               [
                 %{"user_id" => 3, "is_loser" => false, "name" => "testname", "win_count" => 0},
                 %{"user_id" => 2, "is_loser" => false, "name" => "testname", "win_count" => 0}
               ],
               [
                 nil,
                 %{"user_id" => 1, "is_loser" => false, "name" => "testname", "win_count" => 0}
               ]
             ]
    end

    test "data_with_fight_result_for_brackets/1 works fine with valid list data of size 7" do
      match_list = [
        [
          %{"user_id" => 1, "is_loser" => false, "name" => "testname", "win_count" => 0},
          [
            %{"user_id" => 2, "is_loser" => false, "name" => "testname", "win_count" => 0},
            %{"user_id" => 3, "is_loser" => false, "name" => "testname", "win_count" => 0}
          ]
        ],
        [
          [
            %{"user_id" => 4, "is_loser" => false, "name" => "testname", "win_count" => 0},
            %{"user_id" => 5, "is_loser" => false, "name" => "testname", "win_count" => 0}
          ],
          [
            %{"user_id" => 6, "is_loser" => false, "name" => "testname", "win_count" => 0},
            %{"user_id" => 7, "is_loser" => false, "name" => "testname", "win_count" => 0}
          ]
        ]
      ]

      assert Tournaments.data_with_fight_result_for_brackets(match_list) == [
               [
                 %{"user_id" => 7, "is_loser" => false, "name" => "testname", "win_count" => 0},
                 %{"user_id" => 6, "is_loser" => false, "name" => "testname", "win_count" => 0}
               ],
               [
                 %{"user_id" => 5, "is_loser" => false, "name" => "testname", "win_count" => 0},
                 %{"user_id" => 4, "is_loser" => false, "name" => "testname", "win_count" => 0}
               ],
               [
                 %{"user_id" => 3, "is_loser" => false, "name" => "testname", "win_count" => 0},
                 %{"user_id" => 2, "is_loser" => false, "name" => "testname", "win_count" => 0}
               ],
               [
                 nil,
                 %{"user_id" => 1, "is_loser" => false, "name" => "testname", "win_count" => 0}
               ]
             ]
    end

    test "data_for_brackets/1 works fine with valid list data of size 8" do
      match_list = [
        [
          [
            %{"user_id" => 1, "is_loser" => false, "name" => "testname", "win_count" => 0},
            %{"user_id" => 2, "is_loser" => false, "name" => "testname", "win_count" => 0}
          ],
          [
            %{"user_id" => 3, "is_loser" => false, "name" => "testname", "win_count" => 0},
            %{"user_id" => 4, "is_loser" => false, "name" => "testname", "win_count" => 0}
          ]
        ],
        [
          [
            %{"user_id" => 5, "is_loser" => false, "name" => "testname", "win_count" => 0},
            %{"user_id" => 6, "is_loser" => false, "name" => "testname", "win_count" => 0}
          ],
          [
            %{"user_id" => 7, "is_loser" => false, "name" => "testname", "win_count" => 0},
            %{"user_id" => 8, "is_loser" => false, "name" => "testname", "win_count" => 0}
          ]
        ]
      ]

      assert Tournaments.data_with_fight_result_for_brackets(match_list) == [
               [
                 %{"user_id" => 8, "is_loser" => false, "name" => "testname", "win_count" => 0},
                 %{"user_id" => 7, "is_loser" => false, "name" => "testname", "win_count" => 0}
               ],
               [
                 %{"user_id" => 6, "is_loser" => false, "name" => "testname", "win_count" => 0},
                 %{"user_id" => 5, "is_loser" => false, "name" => "testname", "win_count" => 0}
               ],
               [
                 %{"user_id" => 4, "is_loser" => false, "name" => "testname", "win_count" => 0},
                 %{"user_id" => 3, "is_loser" => false, "name" => "testname", "win_count" => 0}
               ],
               [
                 %{"user_id" => 2, "is_loser" => false, "name" => "testname", "win_count" => 0},
                 %{"user_id" => 1, "is_loser" => false, "name" => "testname", "win_count" => 0}
               ]
             ]
    end

    test "data_for_brackets/1 works fine with valid list data of size 9" do
      match_list = [
        [
          [
            %{"user_id" => 1, "is_loser" => false, "name" => "testname", "win_count" => 0},
            %{"user_id" => 2, "is_loser" => false, "name" => "testname", "win_count" => 0}
          ],
          [
            %{"user_id" => 3, "is_loser" => false, "name" => "testname", "win_count" => 0},
            %{"user_id" => 4, "is_loser" => false, "name" => "testname", "win_count" => 0}
          ]
        ],
        [
          [
            %{"user_id" => 5, "is_loser" => false, "name" => "testname", "win_count" => 0},
            %{"user_id" => 6, "is_loser" => false, "name" => "testname", "win_count" => 0}
          ],
          [
            %{"user_id" => 7, "is_loser" => false, "name" => "testname", "win_count" => 0},
            [
              %{"user_id" => 8, "is_loser" => false, "name" => "testname", "win_count" => 0},
              %{"user_id" => 9, "is_loser" => false, "name" => "testname", "win_count" => 0}
            ]
          ]
        ]
      ]

      assert Tournaments.data_with_fight_result_for_brackets(match_list) == [
               [
                 %{"user_id" => 9, "is_loser" => false, "name" => "testname", "win_count" => 0},
                 %{"user_id" => 8, "is_loser" => false, "name" => "testname", "win_count" => 0}
               ],
               [
                 nil,
                 %{"user_id" => 7, "is_loser" => false, "name" => "testname", "win_count" => 0}
               ],
               [
                 %{"user_id" => 6, "is_loser" => false, "name" => "testname", "win_count" => 0},
                 %{"user_id" => 5, "is_loser" => false, "name" => "testname", "win_count" => 0}
               ],
               [
                 %{"user_id" => 4, "is_loser" => false, "name" => "testname", "win_count" => 0},
                 %{"user_id" => 3, "is_loser" => false, "name" => "testname", "win_count" => 0}
               ],
               [
                 %{"user_id" => 2, "is_loser" => false, "name" => "testname", "win_count" => 0},
                 %{"user_id" => 1, "is_loser" => false, "name" => "testname", "win_count" => 0}
               ]
             ]
    end
  end

  describe "get all tournament records" do
    setup [:create_entrant]

    test "get_all_tournament_records/1 works fine with valid data", %{entrant: entrant} do
      user_id = entrant.user_id

      user_id
      |> Tournaments.get_all_tournament_records()
      |> Enum.empty?()
      |> assert()

      setup_tournament_having_participants(entrant.tournament_id)
      Tournaments.finish(entrant.tournament_id, user_id)

      user_id
      |> Tournaments.get_all_tournament_records()
      |> Enum.map(fn record ->
        assert %EntrantLog{} = record
        assert record.tournament_id == entrant.tournament_id
        record
      end)
      |> length()
      |> then(fn records_length ->
        assert records_length == 1
      end)
    end

    # add 7 people
    defp setup_tournament_having_participants(tournament_id) do
      1..7
      |> Enum.map(&fixture_user(num: &1))
      |> Enum.map(&Tournaments.create_entrant(%{"tournament_id" => tournament_id, "user_id" => &1.id}))
    end
  end

  describe "get fighting users" do
    test "get_fighting_users/1 returns valid data" do
      tournament = fixture_tournament(is_started: false)
      create_entrants(7, tournament.id)

      Tournaments.create_entrant(%{
        "user_id" => tournament.master_id,
        "tournament_id" => tournament.id
      })

      start(tournament.master_id, tournament.id)

      assert Tournaments.get_fighting_users(tournament.id) == []

      Progress.insert_match_pending_list_table(tournament.master_id, tournament.id)
      users = Tournaments.get_fighting_users(tournament.id)
      assert length(users) == 1

      Enum.each(users, fn user ->
        assert user.id == tournament.master_id
      end)

      {:ok, opponent} = Tournaments.get_opponent(tournament.id, tournament.master_id)

      Progress.insert_match_pending_list_table(opponent.id, tournament.id)
      users = Tournaments.get_fighting_users(tournament.id)
      assert length(users) == 2

      Progress.delete_match_pending_list(tournament.master_id, tournament.id)
      users = Tournaments.get_fighting_users(tournament.id)
      assert length(users) == 1

      Progress.delete_match_pending_list(opponent.id, tournament.id)
      users = Tournaments.get_fighting_users(tournament.id)
      assert users == []
    end
  end

  describe "get waiting users" do
    test "get_waiting_users/1 returns valid data" do
      tournament = fixture_tournament(is_started: false)
      entrants = create_entrants(7, tournament.id)

      {:ok, entrant} =
        Tournaments.create_entrant(%{
          "user_id" => tournament.master_id,
          "tournament_id" => tournament.id
        })

      entrants = entrants ++ [entrant]
      start(tournament.master_id, tournament.id)

      entrant_id_list = Enum.map(entrants, fn entrant -> entrant.user_id end)
      users = Tournaments.get_waiting_users(tournament.id)

      Enum.each(users, fn user ->
        assert Enum.member?(entrant_id_list, user.id)
      end)

      assert length(users) == length(entrants)

      Progress.insert_match_pending_list_table(tournament.master_id, tournament.id)
      users = Tournaments.get_waiting_users(tournament.id)
      assert length(users) == length(entrants) - 1

      {:ok, opponent} = Tournaments.get_opponent(tournament.id, tournament.master_id)

      Progress.insert_match_pending_list_table(opponent.id, tournament.id)
      users = Tournaments.get_waiting_users(tournament.id)
      assert length(users) == length(entrants) - 2

      Progress.delete_match_pending_list(tournament.master_id, tournament.id)
      users = Tournaments.get_waiting_users(tournament.id)
      assert length(users) == length(entrants) - 1

      Progress.delete_match_pending_list(opponent.id, tournament.id)
      users = Tournaments.get_waiting_users(tournament.id)
      assert length(users) == length(entrants)
    end
  end

  describe "data_with_scores_for_brackets" do
    test "just works with predefined data (size 4 tournament)" do
      tournament = fixture_tournament(is_started: false)
      create_entrants(4, tournament.id)
      Tournaments.start(tournament.id, tournament.master_id)

      {:ok, match_list} =
        tournament.id
        |> Tournaments.get_entrants()
        |> Enum.map(fn x -> x.user_id end)
        |> Tournaments.generate_matchlist()

      count = tournament.count
      Tournaments.initialize_rank(match_list, count, tournament.id)
      Progress.insert_match_list(match_list, tournament.id)

      match_list_with_fight_result = match_list_with_fight_result(match_list)

      match_list_with_fight_result
      |> List.flatten()
      |> Enum.reduce(match_list_with_fight_result, fn x, acc ->
        user = Accounts.get_user(x["user_id"])

        acc
        |> Tournaments.put_value_on_brackets(user.id, %{"name" => user.name})
        |> Tournaments.put_value_on_brackets(user.id, %{"win_count" => 0})
        |> Tournaments.put_value_on_brackets(user.id, %{"icon_path" => user.icon_path})
        |> Tournaments.put_value_on_brackets(user.id, %{"round" => 0})
      end)
      |> Progress.insert_match_list_with_fight_result(tournament.id)

      [user1_id, user2_id, user3_id, user4_id] = List.flatten(match_list)
      Tournaments.store_score(tournament.id, user1_id, user2_id, 13, 2, 1)
      Tournaments.store_score(tournament.id, user3_id, user4_id, 13, 3, 1)

      Progress.get_best_of_x_tournament_match_logs(tournament.id)

      Tournaments.data_with_scores_for_brackets(tournament.id)
      |> Enum.map(fn data ->
        refute data["is_loser"]
        assert data["round"] == 0

        cond do
          data["user_id"] == user1_id ->
            assert data["win_count"] == 1
            assert data["game_scores"] == [13]

          data["user_id"] == user2_id ->
            assert data["win_count"] == 0
            assert data["game_scores"] == [2]

          data["user_id"] == user3_id ->
            assert data["win_count"] == 1
            assert data["game_scores"] == [13]

          data["user_id"] == user4_id ->
            assert data["win_count"] == 0
            assert data["game_scores"] == [3]
        end
      end)
      |> length()
      |> (fn len ->
            assert len == 4
          end).()

      Tournaments.store_score(tournament.id, user3_id, user1_id, 13, 4, 1)

      Tournaments.data_with_scores_for_brackets(tournament.id)
      |> Enum.map(fn data ->
        refute data["is_loser"]
        assert data["round"] == 0

        cond do
          data["user_id"] == user1_id ->
            assert data["win_count"] == 1
            assert data["game_scores"] == [13, 4]

          data["user_id"] == user2_id ->
            assert data["win_count"] == 0
            assert data["game_scores"] == [2]

          data["user_id"] == user3_id ->
            assert data["win_count"] == 2
            assert data["game_scores"] == [13, 13]

          data["user_id"] == user4_id ->
            assert data["win_count"] == 0
            assert data["game_scores"] == [3]
        end
      end)
      |> length()
      |> (fn len ->
            assert len == 4
          end).()
    end
  end

  describe "data_with_scores_for_flexible_brackets" do
    test "works" do
      tournament = fixture_tournament(is_started: false, capacity: 10)
      create_entrants(9, tournament.id)
      Tournaments.start(tournament.id, tournament.master_id)

      {:ok, match_list} =
        tournament.id
        |> Tournaments.get_entrants()
        |> Enum.map(fn x -> x.user_id end)
        |> Tournaments.generate_matchlist()

      count = tournament.count
      Tournaments.initialize_rank(match_list, count, tournament.id)
      Progress.insert_match_list(match_list, tournament.id)

      match_list_with_fight_result = match_list_with_fight_result(match_list)

      match_list_with_fight_result
      |> List.flatten()
      |> Enum.reduce(match_list_with_fight_result, fn x, acc ->
        user = Accounts.get_user(x["user_id"])

        acc
        |> Tournaments.put_value_on_brackets(user.id, %{"name" => user.name})
        |> Tournaments.put_value_on_brackets(user.id, %{"win_count" => 0})
        |> Tournaments.put_value_on_brackets(user.id, %{"icon_path" => user.icon_path})
        |> Tournaments.put_value_on_brackets(user.id, %{"round" => 0})
      end)
      |> Progress.insert_match_list_with_fight_result(tournament.id)

      Tournaments.data_with_scores_for_flexible_brackets(tournament.id)
      |> (fn list ->
            assert is_list(list)
          end).()
    end
  end

  defp setup_team(n) do
    tournament = fixture_tournament(is_started: false, is_team: true, capacity: 2, team_size: n)

    users =
      1..n
      |> Enum.to_list()
      |> Enum.map(fn n ->
        fixture_user(num: n)
      end)
      |> Enum.map(fn user ->
        user.id
      end)

    [leader | members] = users
    size = n

    tournament.id
    |> Tournaments.create_team(size, leader, members)
    |> (fn {:ok, team} ->
          assert team.tournament_id == tournament.id
          assert team.size == size
        end).()

    {tournament, users}
  end

  describe "create_team and get_teams_by_tournament_id and get_team_by_tournament_id_and_user_id" do
    test "works" do
      {tournament, users} = setup_team(5)
      [leader | users] = users

      tournament.id
      |> Tournaments.get_teams_by_tournament_id()
      ~> teams
      |> Enum.map(fn team ->
        assert team.tournament_id == tournament.id
      end)
      |> length()
      |> Kernel.==(1)
      |> assert()

      tournament.id
      |> Tournaments.get_teams_by_tournament_id()
      |> hd()
      |> Map.get(:id)
      |> Tournaments.get_team_members_by_team_id()
      |> Enum.map(fn member ->
        if member.is_leader do
          assert member.user_id == leader
        else
          assert member.user_id in users
        end
      end)
      |> length()
      |> Kernel.==(5)
      |> assert()

      tournament.id
      |> Tournaments.get_team_by_tournament_id_and_user_id(leader)
      ~> team

      assert team.tournament_id == tournament.id
      assert team in teams
    end
  end

  describe "create team without members" do
    test "works" do
      tournament = fixture_tournament(is_team: true)
      user = fixture_user()

      assert {:ok, :leader_only, %Team{is_confirmed: true}} = Tournaments.create_team(tournament.id, 1, user.id, [])
    end
  end

  describe "get_team_members_by_team_id" do
    test "works" do
      {tournament, users} = setup_team(5)

      tournament.id
      |> Tournaments.get_teams_by_tournament_id()
      |> hd()
      |> Map.get(:id)
      |> Tournaments.get_team_members_by_team_id()
      |> Enum.map(fn member ->
        assert member.user_id in users
      end)
      |> length()
      |> Kernel.==(length(users))
      |> assert()
    end
  end

  describe "get_confirmed_team_members_by_tournament_id" do
    test "works" do
      {tournament, users} = setup_team(5)
      [leader | _members] = users

      tournament.id
      |> Tournaments.get_confirmed_team_members_by_tournament_id()
      |> Enum.empty?()
      |> assert()

      tournament.id
      |> Tournaments.get_teams_by_tournament_id()
      |> hd()
      |> Map.get(:id)
      |> Tournaments.get_team_members_by_team_id()
      |> Enum.each(fn member ->
        Tournaments.create_team_invitation(member.id, leader)
      end)

      users
      |> Enum.map(fn user_id ->
        user_id
        |> Tournaments.get_team_invitations_by_user_id()
        |> hd()
        |> Map.get(:id)
        |> Tournaments.confirm_team_invitation()
        |> elem(1)
      end)

      tournament.id
      |> Tournaments.get_confirmed_team_members_by_tournament_id()
      |> length()
      |> Kernel.==(5)
      |> assert()
    end
  end

  describe "get_leader" do
    test "works" do
      {tournament, users} = setup_team(5)
      [leader | _users] = users

      tournament.id
      |> Tournaments.get_teams_by_tournament_id()
      |> hd()
      |> Map.get(:id)
      |> Tournaments.get_leader()
      |> (fn member ->
            assert member.user_id == leader
            refute is_nil(member.user.name)
          end).()
    end
  end

  describe "get_teammates" do
    test "works" do
      {tournament, users} = setup_team(5)
      [leader | users] = users

      another_users =
        6..10
        |> Enum.to_list()
        |> Enum.map(fn n ->
          fixture_user(num: n)
        end)
        |> Enum.map(fn user ->
          user.id
        end)

      [another_leader | another_members] = another_users
      Tournaments.create_team(tournament.id, 5, another_leader, another_members)

      tournament.id
      |> Tournaments.get_teammates(leader)
      |> Enum.map(fn member ->
        assert member.user_id in users || member.user_id == leader
      end)
      |> length()
      |> Kernel.==(5)
      |> assert()
    end
  end

  describe "get_confirmed_teams" do
    test "works" do
      {tournament, users} = setup_team(2)
      [leader | _members] = users

      tournament.id
      |> Tournaments.get_confirmed_teams()
      |> Enum.empty?()
      |> assert()

      tournament.id
      |> Tournaments.get_teams_by_tournament_id()
      |> hd()
      ~> team

      team.id
      |> Tournaments.get_team_members_by_team_id()
      |> Enum.each(fn member ->
        Tournaments.create_team_invitation(member.id, leader)
      end)

      users
      |> Enum.each(fn user_id ->
        user_id
        |> Tournaments.get_team_invitations_by_user_id()
        |> hd()
        |> Map.get(:id)
        |> Tournaments.confirm_team_invitation()
        |> elem(1)
      end)

      tournament.id
      |> Tournaments.get_confirmed_teams()
      |> length()
      |> Kernel.==(1)
      |> assert()
    end
  end

  describe "has_requested_as_team?" do
    test "works" do
      {tournament, users} = setup_team(5)
      [leader | users] = users
      another_user = fixture_user(num: 666)

      leader
      |> Tournaments.has_requested_as_team?(tournament.id)
      |> assert()

      users
      |> Enum.each(fn user ->
        assert Tournaments.has_requested_as_team?(user, tournament.id)
      end)

      another_user
      |> Tournaments.has_requested_as_team?(tournament.id)
      |> refute()
    end
  end

  describe "has_confirmed_as_team?" do
    test "works" do
      tournament = fixture_tournament(is_team: true, type: 2)

      10..15
      |> Enum.to_list()
      |> Enum.map(fn n ->
        [num: n]
        |> fixture_user()
        |> Map.get(:id)
      end)
      |> Enum.chunk_every(tournament.team_size)
      |> Enum.map(fn [leader | members] ->
        tournament.id
        |> Tournaments.create_team(tournament.team_size, leader, members)
        |> elem(1)
      end)
      |> hd()
      ~> team

      team
      |> Map.get(:id)
      |> Tournaments.get_leader()
      |> Map.get(:user_id)
      |> Tournaments.has_confirmed_as_team?(tournament.id)
      |> refute()

      team
      |> Map.get(:id)
      |> Tournaments.get_team_members_by_team_id()
      |> Enum.each(fn member ->
        leader = Tournaments.get_leader(member.team_id)

        member.id
        |> Tournaments.create_team_invitation(leader.user_id)
        |> elem(1)
        |> Map.get(:id)
        |> Tournaments.confirm_team_invitation()
        |> elem(1)
      end)

      team
      |> Map.get(:id)
      |> Tournaments.get_leader()
      |> Map.get(:user_id)
      |> Tournaments.has_confirmed_as_team?(tournament.id)
      |> assert()
    end
  end

  describe "get_invitations_by_tournament_id" do
    test "works" do
      tournament = fixture_tournament(is_team: true, type: 2, capacity: 4)
      fill_with_team(tournament.id)

      tournament.id
      |> Tournaments.get_invitations_by_tournament_id()
      |> Enum.map(fn invitation ->
        assert %TeamInvitation{} = invitation
      end)
    end
  end

  describe "create_team_invitation" do
    test "works" do
      {tournament, users} = setup_team(5)
      [leader | _users] = users

      team =
        tournament.id
        |> Tournaments.get_teams_by_tournament_id()
        |> hd()

      team.id
      |> Tournaments.get_team_members_by_team_id()
      |> Enum.each(fn member ->
        member.id
        |> Tournaments.create_team_invitation(leader)
        |> (fn {:ok, invitation} ->
              assert invitation.team_member_id == member.id
              assert invitation.sender_id == leader
            end).()
      end)
    end
  end

  describe "confirm_team_invitation" do
    test "works" do
      {tournament, users} = setup_team(5)
      [leader | users] = users

      team =
        tournament.id
        |> Tournaments.get_teams_by_tournament_id()
        |> hd()

      team.id
      |> Tournaments.get_team()
      |> Map.get(:is_confirmed)
      |> refute()

      team.id
      |> Tournaments.get_team_members_by_team_id()
      |> Enum.each(fn member ->
        Tournaments.create_team_invitation(member.id, leader)
      end)

      users
      |> Enum.map(fn user_id ->
        user_id
        |> Tournaments.get_team_invitations_by_user_id()
        |> hd()
        |> Map.get(:id)
        |> Tournaments.confirm_team_invitation()
        |> case do
          {:ok, team_member}       -> team_member
          {:error, _, team_member} -> team_member
          _                        -> raise "Invalid result of confirming invitation"
        end
      end)
      |> Enum.map(fn invitation ->
        assert invitation.is_invitation_confirmed
      end)
      |> length()
      |> Kernel.==(4)
      |> assert()

      team.id
      |> Tournaments.get_team()
      |> Map.get(:is_confirmed)
      |> assert()

      tournament.id
      |> Chat.get_chat_rooms_by_tournament_id()
      |> Enum.each(fn room ->
        room.id
        |> Chat.get_chat_members_of_room()
        |> length()
        |> Kernel.==(1 + 5)
        |> assert()
      end)
    end
  end

  describe "delete_team" do
    test "works" do
      {tournament, _users} = setup_team(5)

      tournament.id
      |> Tournaments.get_teams_by_tournament_id()
      |> hd()
      ~> team

      team.id
      |> Tournaments.get_team()
      |> is_nil()
      |> refute()

      assert {:ok, deleted_team} = Tournaments.delete_team(team.id)
      assert deleted_team.id == team.id

      team.id
      |> Tournaments.get_team()
      |> is_nil()
      |> assert()
    end
  end

  describe "delete team and store" do
    test "works" do
      {tournament, _users} = setup_team(5)

      tournament.id
      |> Tournaments.get_teams_by_tournament_id()
      |> hd()
      ~> team

      team.id
      |> Tournaments.get_team()
      |> is_nil()
      |> refute()

      assert {:ok, deleted_team} = Tournaments.delete_team_and_store(team.id)
      assert deleted_team.id == team.id

      team.id
      |> Tournaments.get_team()
      |> is_nil()
      |> assert()

      tournament.id
      |> Log.get_team_logs_by_tournament_id()
      |> Enum.map(fn log ->
        assert log.tournament_id == tournament.id
      end)
      |> length()
      |> Kernel.==(1)
      |> assert()
    end
  end
end

defmodule Milk.TournamentsTest do
  use Milk.DataCase
  use Timex

  alias Milk.{
    Accounts,
    Chat,
    Games,
    Relations,
    Repo,
    TournamentProgress,
    Tournaments
  }

  alias Milk.Tournaments.{
    Tournament,
    Entrant,
    TournamentChatTopic
  }

  alias Milk.Log.{
    EntrantLog
  }

  alias Milk.Accounts.User

  # 外部キーが二つ以上の場合は %{"capacity" => 42} のようにしなければいけない
  @valid_attrs %{
    "capacity" => 42,
    "deadline" => "2010-04-17T14:00:00Z",
    "description" => "some description",
    "event_date" => "2010-04-17T14:00:00Z",
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
    capacity: 43,
    deadline: "2011-05-18T15:01:01Z",
    description: "some updated description",
    event_date: "2011-05-18T15:01:01Z",
    name: "some updated name",
    type: 43,
    url: "some updated url"
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

  defp fixture_tournament(opts \\ []) do
    # FIXME: ここのデフォルト値は本当はfalseのほうがよさそう
    is_started = opts[:is_started]
      |> is_nil()
      |> unless do
        opts[:is_started]
      else
        true
      end

    is_team = opts[:is_team]
      |> is_nil()
      |> unless do
        opts[:is_team]
      else
        false
      end

    master_id = opts[:master_id]
      |> is_nil()
      |> unless do
        opts[:master_id]
      else
        {:ok, user} =
          Accounts.create_user(%{
            "name" => "name",
            "email" => "e@mail.com",
            "password" => "Password123"
          })

        user.id
      end

    {:ok, tournament} =
      @valid_attrs
      |> Map.put("is_started", is_started)
      |> Map.put("master_id", master_id)
      |> Map.put("is_team", is_team)
      |> Tournaments.create_tournament()

    tournament
  end

  defp fixture(:game) do
    {:ok, game} = Games.create_game(%{"title" => "Test Game"})
    game
  end

  defp fixture(:assistant) do
    user = fixture_user()

    {:ok, tournament} =
      @valid_attrs
      |> Map.put("master_id", user.id)
      |> Map.put("is_started", false)
      |> Tournaments.create_tournament()

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

    {:ok, topic} =
      %{
        "topic_name" => "name",
        "tournament_id" => tournament.id,
        "chat_room_id" => chat_room.id,
        "tab_index" => 1
      }
      |> Tournaments.create_tournament_chat_topic()

    topic
  end

  defp fixture_user(opts \\ []) do
    num_str =
      opts[:num]
      |> is_nil()
      |> unless do
        to_string(opts[:num])
      else
        "1"
      end

    {:ok, user} =
      Accounts.create_user(%{
        "name" => "name" <> num_str,
        "email" => "e1" <> num_str <> "mail.com",
        "password" => "Password123"
      })

    user
  end

  defp fixture_entrant(opts \\ %{}) do
    tournament =
      opts["tournament_id"]
      |> is_nil()
      |> unless do
        Tournaments.get_tournament(opts["tournament_id"])
      else
        fixture_tournament()
      end

    user_id =
      opts["user_id"]
      |> is_nil()
      |> unless do
        opts["user_id"]
      else
        tournament.master_id
      end

    {:ok, entrant} =
      %{@entrant_create_attrs | "tournament_id" => tournament.id, "user_id" => user_id}
      |> Tournaments.create_entrant()

    entrant
  end

  describe "get tournament" do
    test "get_tournament/1" do
      tournament = fixture_tournament()

      t = Tournaments.get_tournament(tournament.id)
      assert t.capacity == tournament.capacity
      assert t.description == tournament.description
      assert t.name == tournament.name
      assert t.type == tournament.type
      assert t.url == tournament.url
      assert t.count == 0
      assert t.entrant == []
      refute t.is_team
      assert t.game_name == tournament.game_name
    end

    test "get_tournament/1 fails" do
      1
      |> Tournaments.get_tournament()
      |> is_nil()
      |> assert()
    end

    test "get_tournament_by_room_id works" do
      tournament = fixture_tournament()

      tournament.id
      |> Chat.get_chat_rooms_by_tournament_id()
      |> Enum.map(fn room ->
        room.id
        |> Tournaments.get_tournament_by_room_id()
        |> (fn t ->
              assert t.id == tournament.id
            end).()
      end)
    end

    test "get_tournament_by_room_id returns nil" do
      Tournaments.get_tournament_by_room_id(-1)
      |> Kernel.==({:error, "the tournament was not found."})
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
      |> (fn len ->
            assert len == 1
          end).()
    end

    test "get_tournaments_by_master_id/1 fails to return tournaments of a user" do
      user = fixture_user()
      _tournament = fixture_tournament()
      assert length(Tournaments.get_tournaments_by_master_id(user.id)) == 0
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
        assert t.type == tournament.type
      end)
      |> length()
      |> (fn len ->
            assert len == 1
          end).()
    end

    test "get_ongoing_tournaments_by_master_id/1 fails to return user's ongoing tournaments" do
      tournament = fixture_tournament()
      assert length(Tournaments.get_ongoing_tournaments_by_master_id(tournament.master_id)) == 0
    end

    test "get_tournament/1 with valid data works fine" do
      tournament = fixture_tournament()
      assert %Tournament{} = obtained_tournament = Tournaments.get_tournament(tournament.id)
      assert obtained_tournament.id == tournament.id
    end

    test "get_participating_tournaments!/1 with valid data works fine" do
      entrant = fixture_entrant()
      _tournament = Tournaments.get_tournament(entrant.tournament_id)

      assert tournaments = Tournaments.get_participating_tournaments(entrant.user_id, 0)
      assert is_list(tournaments)

      Enum.each(tournaments, fn tournament ->
        assert %Tournament{} = tournament
      end)
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
      assert tournament.capacity == 42
      assert tournament.deadline == "2010-04-17T14:00:00Z"
      assert tournament.description == "some description"
      assert tournament.event_date == "2010-04-17T14:00:00Z"
      assert tournament.name == "some name"
      assert tournament.type == 0
      assert tournament.url == "somesomeurl"
    end

    test "create_tournament/1 with invalid data returns error changeset" do
      assert {:error, _} = Tournaments.create_tournament(@invalid_attrs)
    end
  end

  describe "verify?" do
    test "works" do
      tournament = fixture_tournament()
      assert Tournaments.verify?(tournament.id, "passwd")
      refute Tournaments.verify?(tournament.id, "wrong_pw")
    end
  end

  describe "update tournament" do
    test "update_tournament/2 with valid data updates the tournament" do
      tournament = fixture_tournament()

      assert {:ok, %Tournament{} = tournament} =
               Tournaments.update_tournament(tournament, @update_attrs)

      assert tournament.capacity == 43
      assert tournament.deadline == "2011-05-18T15:01:01Z"
      assert tournament.description == "some updated description"
      assert tournament.event_date == "2011-05-18T15:01:01Z"
      assert tournament.name == "some updated name"
      assert tournament.type == 43
      assert tournament.url == "some updated url"
    end

    test "update_tournament/2 with invalid data returns error changeset" do
      tournament = fixture_tournament()
      assert {:error, _} = Tournaments.update_tournament(tournament, @invalid_attrs)
    end
  end

  describe "delete tournament" do
    test "delete_tournament/1 of Tournament structure works fine with a valid data" do
      tournament = fixture_tournament()
      assert {:ok, %Tournament{}} = Tournaments.delete_tournament(tournament)
      refute Tournaments.get_tournament(tournament.id)
    end

    test "delete_tournament/1 of map works fine with a valid data" do
      user = fixture_user()

      {:ok, tournament} =
        @valid_attrs
        |> Map.put("master_id", user.id)
        |> Tournaments.create_tournament()

      assert {:ok, %Tournament{}} = Tournaments.delete_tournament(tournament)
      refute Tournaments.get_tournament(tournament.id)
    end

    test "delete_tournament/1 of id works fine with a valid data" do
      tournament = fixture_tournament()
      assert {:ok, %Tournament{}} = Tournaments.delete_tournament(tournament.id)
      refute Tournaments.get_tournament(tournament.id)
    end
  end

  describe "home" do
    @home_attrs %{
      deadline: "2031-05-18T15:01:01Z",
      event_date: "2031-05-18T15:01:01Z"
    }

    test "home_tournament/3 with user_id" do
      user1 = fixture_user()
      tournament = fixture_tournament()
      {:ok, _} = Tournaments.update_tournament(tournament, @home_attrs)

      Relations.block(user1.id, tournament.master_id)

      "2020-05-12 16:55:53 +0000"
      |> Tournaments.home_tournament(0, user1.id)
      |> length()
      |> (fn len ->
            assert len == 0
          end).()
    end

    test "home_tournament/3 without user_id" do
      tournament = fixture_tournament()
      {:ok, _} = Tournaments.update_tournament(tournament, @home_attrs)

      "2020-05-12 16:55:53 +0000"
      |> Tournaments.home_tournament(0)
      |> length()
      |> (fn len ->
            assert len == 1
          end).()
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
      |> (fn len ->
            assert len == 1
          end).()
    end

    test "home_tournament_fav/1 fails to return tournaments which is filtered by favorite users for home screen" do
      tournament = fixture_tournament()
      {:ok, _} = Tournaments.update_tournament(tournament, @home_attrs)

      tournament.master_id
      |> Tournaments.home_tournament_fav()
      |> length()
      |> (fn len ->
            assert len == 0
          end).()
    end

    test "home_tournament_plan/1 returns user's tournaments" do
      tournament = fixture_tournament()
      {:ok, _} = Tournaments.update_tournament(tournament, @home_attrs)

      tournament.master_id
      |> Tournaments.home_tournament_plan()
      |> (fn len ->
            refute len == 0
          end).()
    end

    test "home_tournament_plan/1 fails to return user's tournaments" do
      tournament = fixture_tournament()
      assert length(Tournaments.home_tournament_plan(tournament.master_id)) == 0
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
      |> length()
      |> Kernel.==(0)
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
      t = Tournaments.get_tournament_by_url(tournament.url)
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

      assert tournaments = Tournaments.get_tournament_by_game_id(game.id)
      assert is_list(tournaments)

      Enum.each(tournaments, fn tournament ->
        assert %Tournament{} = tournament
      end)
    end
  end

  describe "get entrant" do
    setup [:create_entrant]

    test "list_entrant/0 works fine" do
      assert entrants = Tournaments.list_entrant()
      assert is_list(entrants)

      Enum.each(entrants, fn entrant ->
        assert %Entrant{} = entrant
      end)
    end

    test "get_entrant!/1 work with valid data", %{entrant: entrant} do
      assert %Entrant{} = obtained_entrant = Tournaments.get_entrant!(entrant.id)
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
      |> (fn len ->
            assert len == length(entrants)
          end).()
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
      |> (fn len ->
            assert len == length(entrants) - 1
          end).()
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

      Tournaments.create_entrant(entrant_params)
      |> Kernel.==({:error, "already joined"})
      |> assert()
    end

    test "create_entrant/1 returns a team error when the tournament requires team participation" do
      user = fixture_user()
      tournament = fixture_tournament(is_team: true)

      entrant_params =
        @entrant_create_attrs
        |> Map.put("tournament_id", tournament.id)
        |> Map.put("user_id", user.id)

      Tournaments.create_entrant(entrant_params)
      |> Kernel.==({:error, "requires team"})
      |> assert()
    end

    test "create_entrant/1 returns a multi error when it runs with same parameter at one time." do
      # tournament and user for entrant_param
      user0 = fixture_user()
      user1 = fixture_user(num: 0)
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
      assert {:multierror, _} = Task.await(create_entrant_task2)
    end
  end

  describe "update entrant" do
    setup [:create_entrant]

    test "update_entrant/2 works fine with a valid data", %{entrant: entrant} do
      update_attrs = %{"rank" => 1}
      assert {:ok, _entrant} = Tournaments.update_entrant(entrant, update_attrs)
    end
  end

  describe "delete entrant" do
    setup [:create_entrant]

    test "delete_entrant/2 works fine with a valid data", %{entrant: entrant} do
      assert {:ok, %Entrant{} = entrant} =
               Tournaments.delete_entrant(entrant.tournament_id, entrant.user_id)

      assert %Ecto.NoResultsError{} = catch_error(Tournaments.get_entrant!(entrant.id))
    end

    test "delete_entrant/1 works fine with a valid data", %{entrant: entrant} do
      assert {:ok, %Entrant{} = entrant} = Tournaments.delete_entrant(entrant)
      assert %Ecto.NoResultsError{} = catch_error(Tournaments.get_entrant!(entrant.id))
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
      assert {:ok, _tournament} = Tournaments.start(tournament.master_id, tournament.id)

      assert {:error, "tournament is already started"} ==
               Tournaments.start(tournament.master_id, tournament.id)
    end

    test "start/2 with only one entrant returns too few entrants error.", %{
      tournament: tournament
    } do
      assert {:error, "too few entrants"} ==
               Tournaments.start(tournament.master_id, tournament.id)
    end

    test "start/2 with nil returns master_id or tournament_id is nil error", %{
      tournament: _tournament
    } do
      assert {:error, "master_id or tournament_id is nil"} == Tournaments.start(nil, nil)
      assert {:error, "master_id or tournament_id is nil"} == Tournaments.start(1, nil)
      assert {:error, "master_id or tournament_id is nil"} == Tournaments.start(nil, 1)
    end

    test "start/2 with undefined tournament returns cannot find tournament error", %{
      tournament: _tournament
    } do
      # FIXME: ここには来ない
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

    test "get_opponent/2 with valid data works fine", %{tournament: tournament} do
      entrants = create_entrants(6, tournament.id)
      id_list = Enum.map(entrants, fn entrant -> entrant.user_id end)

      integer_input = Enum.slice(id_list, 0..1)
      list_input = [hd(id_list)] ++ [Enum.slice(id_list, 1..2)]

      assert {:ok, opponent} = Tournaments.get_opponent(integer_input, hd(id_list))
      assert opponent["id"] == integer_input |> tl() |> hd()
      assert {:wait, nil} = Tournaments.get_opponent(list_input, hd(id_list))
    end

    test "get_opponent/2 with invalid data does not work", %{tournament: tournament} do
      entrants = create_entrants(6, tournament.id)
      id_list = Enum.map(entrants, fn entrant -> entrant.user_id end)

      integer_input = Enum.slice(id_list, 0..1)

      assert {:error, _} = Tournaments.get_opponent(integer_input, hd(id_list) - 1)
    end

    test "get_opponent/2 does not work with insufficient entrants", %{tournament: tournament} do
      entrants = create_entrants(1, tournament.id)
      id_list = Enum.map(entrants, fn entrant -> entrant.user_id end)

      assert {:error, _} = Tournaments.get_opponent(id_list, hd(id_list))
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
      assert Tournaments.get_rank(entrant.tournament_id, entrant.user_id) == entrant.rank
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

  describe "state!" do
    test "state!/2 returns IsNotStarted" do
      %{tournament: tournament} = create_tournament_for_flow(nil)
      assert "IsNotStarted" == Tournaments.state!(tournament.id, tournament.master_id)
    end

    test "state!/2 returns IsManager" do
      %{tournament: tournament} = create_tournament_for_flow(nil)
      create_entrants(8, tournament.id)
      start(tournament.master_id, tournament.id)
      assert "IsManager" == Tournaments.state!(tournament.id, tournament.master_id)
    end

    test "state!/2 returns IsAssistant" do
      %{tournament: tournament} = create_tournament_for_flow(nil)
      create_entrants(8, tournament.id)
      assistant_id = fixture_user(num: 10).id

      Tournaments.create_assistants(%{
        "tournament_id" => tournament.id,
        "user_id" => [assistant_id]
      })

      start(tournament.master_id, tournament.id)
      assert "IsAssistant" == Tournaments.state!(tournament.id, assistant_id)
    end

    test "state!/2 returns IsLoser" do
      %{tournament: tournament} = create_tournament_for_flow(nil)
      create_entrants(7, tournament.id)

      Tournaments.create_entrant(%{
        "user_id" => tournament.master_id,
        "tournament_id" => tournament.id
      })

      start(tournament.master_id, tournament.id)
      delete_loser(tournament.id, [tournament.master_id])
      assert "IsLoser" == Tournaments.state!(tournament.id, tournament.master_id)
    end

    test "state!/2 returns IsAlone" do
      %{tournament: tournament} = create_tournament_for_flow(nil)
      create_entrants(7, tournament.id)

      Tournaments.create_entrant(%{
        "user_id" => tournament.master_id,
        "tournament_id" => tournament.id
      })

      start(tournament.master_id, tournament.id)

      match_list = TournamentProgress.get_match_list(tournament.id)

      match = Tournaments.find_match(match_list, tournament.master_id)
      {:ok, opponent} = Tournaments.get_opponent(match, tournament.master_id)

      delete_loser(tournament.id, [opponent["id"]])
      assert "IsAlone" == Tournaments.state!(tournament.id, tournament.master_id)
    end

    test "state!/2 returns IsPending" do
      %{tournament: tournament} = create_tournament_for_flow(nil)
      create_entrants(7, tournament.id)

      Tournaments.create_entrant(%{
        "user_id" => tournament.master_id,
        "tournament_id" => tournament.id
      })

      start(tournament.master_id, tournament.id)

      match_list = TournamentProgress.get_match_list(tournament.id)

      match = Tournaments.find_match(match_list, tournament.master_id)
      {:ok, opponent} = Tournaments.get_opponent(match, tournament.master_id)

      pending_list =
        TournamentProgress.get_match_pending_list(tournament.master_id, tournament.id)

      assert pending_list == []

      opponent_pending_list =
        TournamentProgress.get_match_pending_list(opponent["id"], tournament.id)

      assert opponent_pending_list == []

      TournamentProgress.insert_match_pending_list_table(tournament.master_id, tournament.id)
      TournamentProgress.insert_match_pending_list_table(opponent["id"], tournament.id)

      assert "IsPending" == Tournaments.state!(tournament.id, tournament.master_id)
    end

    test "state!/2 returns IsWaitingForStart" do
      %{tournament: tournament} = create_tournament_for_flow(nil)
      create_entrants(7, tournament.id)

      Tournaments.create_entrant(%{
        "user_id" => tournament.master_id,
        "tournament_id" => tournament.id
      })

      start(tournament.master_id, tournament.id)

      pending_list =
        TournamentProgress.get_match_pending_list(tournament.master_id, tournament.id)

      assert pending_list == []
      TournamentProgress.insert_match_pending_list_table(tournament.master_id, tournament.id)

      assert "IsWaitingForStart" == Tournaments.state!(tournament.id, tournament.master_id)
    end

    test "state!2 returns IsInMatch" do
      %{tournament: tournament} = create_tournament_for_flow(nil)
      create_entrants(7, tournament.id)

      Tournaments.create_entrant(%{
        "user_id" => tournament.master_id,
        "tournament_id" => tournament.id
      })

      start(tournament.master_id, tournament.id)
      assert "IsInMatch" == Tournaments.state!(tournament.id, tournament.master_id)
    end
  end

  defp start(master_id, tournament_id) do
    Tournaments.start(master_id, tournament_id)

    {:ok, match_list} =
      Tournaments.get_entrants(tournament_id)
      |> Enum.map(fn x -> x.user_id end)
      |> Tournaments.generate_matchlist()

    count =
      Tournaments.get_tournament(tournament_id)
      |> Map.get(:count)

    match_list
    |> Tournaments.initialize_rank(count, tournament_id)

    match_list
    |> TournamentProgress.insert_match_list(tournament_id)

    list_with_fight_result =
      match_list
      |> match_list_with_fight_result()

    lis =
      list_with_fight_result
      |> Tournamex.match_list_to_list()

    Enum.reduce(lis, list_with_fight_result, fn x, acc ->
      user = Accounts.get_user(x["user_id"])

      acc
      |> Tournaments.put_value_on_brackets(user.id, %{"name" => user.name})
      |> Tournaments.put_value_on_brackets(user.id, %{"win_count" => 0})
      |> Tournaments.put_value_on_brackets(user.id, %{"icon_path" => user.icon_path})
    end)
    |> TournamentProgress.insert_match_list_with_fight_result(tournament_id)
  end

  defp match_list_with_fight_result(match_list) do
    Tournaments.initialize_match_list_with_fight_result(match_list)
  end

  defp delete_loser(tournament_id, loser_list) do
    match_list = TournamentProgress.get_match_list(tournament_id)

    match_list
    |> Tournaments.find_match(hd(loser_list))
    |> Enum.each(fn user_id ->
      TournamentProgress.delete_match_pending_list(user_id, tournament_id)
      TournamentProgress.delete_fight_result(user_id, tournament_id)
    end)

    renew_match_list(tournament_id, match_list, loser_list)
    get_lost(tournament_id, match_list, loser_list)
  end

  defp renew_match_list(tournament_id, match_list, loser_list) do
    Tournaments.promote_winners_by_loser(tournament_id, match_list, loser_list)
    updated_match_list = Tournaments.delete_loser(match_list, loser_list)
    TournamentProgress.delete_match_list(tournament_id)
    TournamentProgress.insert_match_list(updated_match_list, tournament_id)
  end

  defp get_lost(tournament_id, _match_list, [loser]) do
    match_list =
      tournament_id
      |> TournamentProgress.get_match_list_with_fight_result()

    updated_match_list = Tournaments.get_lost(match_list, loser)
    TournamentProgress.delete_match_list_with_fight_result(tournament_id)
    TournamentProgress.insert_match_list_with_fight_result(updated_match_list, tournament_id)
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
        assistant = Tournaments.get_assistant!(assistant.id)
        assert assistant.user_id == hd(assistant_attr["user_id"])
        assert assistant.tournament_id == assistant_attr["tournament_id"]
      end)
      |> length()
      |> (fn len ->
            assert len == 1
          end).()
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
      |> (fn len ->
            assert len == 1
          end).()
    end
  end

  describe "create assistants" do
    test "create_assistants/1 with valid data works fine" do
      assert assistant = fixture(:assistant)
    end
  end

  describe "get tournament chat topic" do
    test "list_tournament_chat_topics/0 works fine" do
      fixture(:tournament_chat_topic)
      assert is_list(Tournaments.list_tournament_chat_topics())
      refute Tournaments.list_tournament_chat_topics() == 0
    end

    test "get_tournament_chat_topic!/1 with valid data works fine" do
      topic = fixture(:tournament_chat_topic)

      assert %TournamentChatTopic{} =
               obtained_topic = Tournaments.get_tournament_chat_topic!(topic.id)

      assert obtained_topic.id == topic.id
      assert obtained_topic.topic_name == topic.topic_name
    end

    test "get_tabs_by_tournament_id/1 with valid data works fine" do
      topic = fixture(:tournament_chat_topic)
      tabs = Tournaments.get_tabs_by_tournament_id(topic.tournament_id)
      assert is_list(tabs)
      refute length(tabs) == 0

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

      assert %Ecto.NoResultsError{} =
               catch_error(Tournaments.get_tournament_chat_topic!(deleted_topic.id))
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
      refute length(ranked_entrants) == 0
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
      # 参加者作成，マッチリストを生成してTournamentProgressに登録
      {_, match_list} =
        create_entrants(num, entrant.tournament_id)
        |> Enum.map(fn x -> %{x | rank: num + 1} end)
        |> Kernel.++([%{entrant | rank: num + 1}])
        |> Enum.map(fn entrant -> entrant.user_id end)
        |> Tournaments.generate_matchlist()

      TournamentProgress.insert_match_list(match_list, entrant.tournament_id)

      assert {:ok, promoted} = Tournaments.promote_rank(attrs)
    end

    test "promote_rank/1 returns error with invalid attrs(tournament_id)", %{entrant: entrant} do
      # promote_rankの引数となるattrs
      attrs = %{
        "tournament_id" => -1,
        "user_id" => entrant.user_id
      }

      # numは生成する参加者の数で後に一人追加するので8 - 1 = 7
      num = 7
      # 参加者作成，マッチリストを生成してTournamentProgressに登録
      create_entrants(num, entrant.tournament_id)
      |> Enum.map(fn x -> %{x | rank: num + 1} end)
      |> Kernel.++([%{entrant | rank: num + 1}])
      |> Tournaments.generate_matchlist()
      |> TournamentProgress.insert_match_list(entrant.tournament_id)

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
      # 参加者作成，マッチリストを生成してTournamentProgressに登録
      create_entrants(num, entrant.tournament_id)
      |> Enum.map(fn x -> %{x | rank: num + 1} end)
      |> Kernel.++([%{entrant | rank: num + 1}])
      |> Tournaments.generate_matchlist()
      |> TournamentProgress.insert_match_list(entrant.tournament_id)

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
      # 参加者作成，マッチリストを生成してTournamentProgressに登録
      create_entrants(num, entrant.tournament_id)
      |> Enum.map(fn x -> %{x | rank: num + 1} end)
      |> Kernel.++([%{entrant | rank: num + 1}])
      |> Tournaments.generate_matchlist()
      |> TournamentProgress.insert_match_list(entrant.tournament_id)

      assert {:error, "undefined user"} = Tournaments.promote_rank(attrs)
    end

    test "run promote_rank/1 in a row with 8 entrants", %{entrant: entrant} do
      attrs = %{
        "tournament_id" => entrant.tournament_id,
        "user_id" => entrant.user_id
      }

      # numは生成する参加者の数で後に一人追加するので8 - 1 = 7
      num = 7
      # 参加者作成，マッチリストを生成してTournamentProgressに登録
      {:ok, match_list} =
        create_entrants(num, entrant.tournament_id)
        |> Enum.map(fn x -> %{x | rank: num + 1} end)
        |> Kernel.++([%{entrant | rank: num + 1}])
        |> Enum.map(fn entrant -> entrant.user_id end)
        |> Tournaments.generate_matchlist()

      TournamentProgress.insert_match_list(match_list, entrant.tournament_id)

      assert {:ok, _promoted} = Tournaments.promote_rank(attrs)
      assert Tournaments.get_rank(entrant.tournament_id, entrant.user_id) == 4

      {:ok, opponent} =
        match_list
        |> Tournaments.find_match(entrant.user_id)
        |> Tournaments.get_opponent(entrant.user_id)

      TournamentProgress.delete_match_list(entrant.tournament_id)
      updated = Tournaments.delete_loser(match_list, opponent["id"])

      TournamentProgress.insert_match_list(updated, entrant.tournament_id)

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

      TournamentProgress.insert_match_list(match_list, entrant.tournament_id)

      assert {:ok, _promoted} = Tournaments.promote_rank(attrs)
      assert Tournaments.get_rank(entrant.tournament_id, entrant.user_id) == 2

      {:ok, opponent} =
        match_list
        |> Tournaments.find_match(entrant.user_id)
        |> Tournaments.get_opponent(entrant.user_id)

      TournamentProgress.delete_match_list(entrant.tournament_id)
      updated = Tournaments.delete_loser(match_list, opponent["id"])

      TournamentProgress.insert_match_list(updated, entrant.tournament_id)

      assert {:wait, nil} = Tournaments.promote_rank(attrs)
    end

    test "run promote_rank/1 in a row with 2 entrants", %{entrant: entrant} do
      attrs = %{
        "tournament_id" => entrant.tournament_id,
        "user_id" => entrant.user_id
      }

      num = 1

      {:ok, match_list} =
        create_entrants(num, entrant.tournament_id)
        |> Enum.map(fn x -> %{x | rank: num + 1} end)
        |> Kernel.++([%{entrant | rank: num + 1}])
        |> Enum.map(fn entrant -> entrant.user_id end)
        |> Tournaments.generate_matchlist()

      TournamentProgress.insert_match_list(match_list, entrant.tournament_id)

      assert {:ok, _promoted} = Tournaments.promote_rank(attrs)
      assert Tournaments.get_rank(entrant.tournament_id, entrant.user_id) == 1

      {:ok, opponent} =
        match_list
        |> Tournaments.find_match(entrant.user_id)
        |> Tournaments.get_opponent(entrant.user_id)

      TournamentProgress.delete_match_list(entrant.tournament_id)
      updated = Tournaments.delete_loser(match_list, opponent["id"])

      TournamentProgress.insert_match_list(updated, entrant.tournament_id)
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
      |> length()
      |> (fn records_length ->
            assert records_length == 0
          end).()

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
      |> (fn records_length ->
            assert records_length == 1
          end).()
    end

    # add 7 people
    defp setup_tournament_having_participants(tournament_id) do
      1..7
      |> Enum.map(fn n ->
        fixture_user(num: n)
      end)
      |> Enum.map(fn user ->
        %{"tournament_id" => tournament_id, "user_id" => user.id}
        |> Tournaments.create_entrant()
      end)
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

      TournamentProgress.insert_match_pending_list_table(tournament.master_id, tournament.id)
      users = Tournaments.get_fighting_users(tournament.id)
      assert length(users) == 1

      Enum.each(users, fn user ->
        user.id == tournament.master_id
      end)

      match_list =
        tournament.id
        |> TournamentProgress.get_match_list()

      match = Tournaments.find_match(match_list, tournament.master_id)
      {:ok, opponent} = Tournaments.get_opponent(match, tournament.master_id)

      TournamentProgress.insert_match_pending_list_table(opponent["id"], tournament.id)
      users = Tournaments.get_fighting_users(tournament.id)
      assert length(users) == 2

      TournamentProgress.delete_match_pending_list(tournament.master_id, tournament.id)
      users = Tournaments.get_fighting_users(tournament.id)
      assert length(users) == 1

      TournamentProgress.delete_match_pending_list(opponent["id"], tournament.id)
      users = Tournaments.get_fighting_users(tournament.id)
      assert length(users) == 0
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

      TournamentProgress.insert_match_pending_list_table(tournament.master_id, tournament.id)
      users = Tournaments.get_waiting_users(tournament.id)
      assert length(users) == length(entrants) - 1

      match_list =
        tournament.id
        |> TournamentProgress.get_match_list()

      match = Tournaments.find_match(match_list, tournament.master_id)
      {:ok, opponent} = Tournaments.get_opponent(match, tournament.master_id)

      TournamentProgress.insert_match_pending_list_table(opponent["id"], tournament.id)
      users = Tournaments.get_waiting_users(tournament.id)
      assert length(users) == length(entrants) - 2

      TournamentProgress.delete_match_pending_list(tournament.master_id, tournament.id)
      users = Tournaments.get_waiting_users(tournament.id)
      assert length(users) == length(entrants) - 1

      TournamentProgress.delete_match_pending_list(opponent["id"], tournament.id)
      users = Tournaments.get_waiting_users(tournament.id)
      assert length(users) == length(entrants)
    end
  end

  describe "data_with_scores_for_brackets" do
    test "just works with predefined data (size 4 tournament)" do
      tournament = fixture_tournament(is_started: false)
      create_entrants(4, tournament.id)
      Tournaments.start(tournament.master_id, tournament.id)

      {:ok, match_list} =
        tournament.id
        |> Tournaments.get_entrants()
        |> Enum.map(fn x -> x.user_id end)
        |> Tournaments.generate_matchlist()

      count = tournament.count
      Tournaments.initialize_rank(match_list, count, tournament.id)
      TournamentProgress.insert_match_list(match_list, tournament.id)

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
      |> TournamentProgress.insert_match_list_with_fight_result(tournament.id)

      [user1_id, user2_id, user3_id, user4_id] = List.flatten(match_list)
      Tournaments.score(tournament.id, user1_id, user2_id, 13, 2, 1)
      Tournaments.score(tournament.id, user3_id, user4_id, 13, 3, 1)

      TournamentProgress.get_best_of_x_tournament_match_logs(tournament.id)

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

      Tournaments.score(tournament.id, user3_id, user1_id, 13, 4, 1)

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
      tournament = fixture_tournament(is_started: false)
      create_entrants(9, tournament.id)
      Tournaments.start(tournament.master_id, tournament.id)

      {:ok, match_list} =
        tournament.id
        |> Tournaments.get_entrants()
        |> Enum.map(fn x -> x.user_id end)
        |> Tournaments.generate_matchlist()

      count = tournament.count
      Tournaments.initialize_rank(match_list, count, tournament.id)
      TournamentProgress.insert_match_list(match_list, tournament.id)

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
      |> TournamentProgress.insert_match_list_with_fight_result(tournament.id)

      Tournaments.data_with_scores_for_flexible_brackets(tournament.id)
      |> (fn list ->
            assert is_list(list)
          end).()
    end
  end

  defp setup_team(n) do
    tournament = fixture_tournament([is_started: false, is_team: true])
    users = 1..n
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

  describe "create_team and get_teams_by_tournament_id" do
    test "works" do
      {tournament, users} = setup_team(5)
      [leader | users] = users

      tournament.id
      |> Tournaments.get_teams_by_tournament_id()
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
    end
  end

  describe "get_teammates" do
    test "works" do
      {tournament, users} = setup_team(5)
      [leader | users] = users

      another_users = 6..10
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
      [leader | members] = users

      tournament.id
      |> Tournaments.get_confirmed_teams()
      |> length()
      |> Kernel.==(0)
      |> assert()

      team = tournament.id
        |> Tournaments.get_teams_by_tournament_id()
        |> hd()

      team.id
      |> Tournaments.get_team_members_by_team_id()
      |> Enum.each(fn member ->
        Tournaments.create_team_invitation(member.id, leader, "test")
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

      another_user
      |> Tournaments.has_requested_as_team?(tournament.id)
      |> refute()
    end
  end

  describe "create_team_invitation" do
    test "works" do
      {tournament, users} = setup_team(5)
      [leader | users] = users

      team = tournament.id
        |> Tournaments.get_teams_by_tournament_id()
        |> hd()

      team.id
      |> Tournaments.get_team_members_by_team_id()
      |> Enum.each(fn member ->
        member.id
        |> Tournaments.create_team_invitation(leader, "test")
        |> (fn {:ok, invitation} ->
          assert invitation.team_member_id == member.id
          assert invitation.sender_id == leader
          assert invitation.text == "test"
        end).()
      end)
    end
  end

  describe "confirm_team_invitation" do
    test "works" do
      {tournament, users} = setup_team(5)
      [leader | users] = users

      team = tournament.id
        |> Tournaments.get_teams_by_tournament_id()
        |> hd()

      team.id
      |> Tournaments.get_team_members_by_team_id()
      |> Enum.each(fn member ->
        Tournaments.create_team_invitation(member.id, leader, "test")
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
      |> Enum.map(fn invitation ->
        assert invitation.is_invitation_confirmed
      end)
      |> length()
      |> Kernel.==(4)
      |> assert()
    end
  end
end

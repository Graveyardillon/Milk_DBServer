defmodule MilkWeb.TournamentControllerTest do
  use MilkWeb.ConnCase

  alias Milk.{
    Accounts,
    Relations,
    TournamentProgress,
    Tournaments
  }

  require Logger

  @entrant_create_attrs %{
    "rank" => 42,
    "user_id" => -1,
    "tournament_id" => -1
  }
  @create_attrs %{
    "capacity" => 42,
    "deadline" => "2010-04-17T14:00:00Z",
    "description" => "some description",
    "event_date" => "2010-04-17T14:00:00Z",
    "master_id" => 42,
    "name" => "some name",
    "type" => 42,
    "join" => "true",
    "url" => "some url",
    "platform_id" => 1
  }
  @create_incoming_attrs %{
    "capacity" => 42,
    "deadline" => "2100-04-17T14:00:00Z",
    "description" => "some description",
    "event_date" => "2100-04-17T14:00:00Z",
    "master_id" => 42,
    "name" => "some name",
    "type" => 42,
    "join" => "true",
    "url" => "some url",
    "platform_id" => 1
  }
  @update_attrs %{
    "capacity" => 4200,
    "url" => "updated url"
  }
  @invalid_attrs %{"capacity" => nil, "deadline" => nil, "description" => nil, "event_date" => nil, "game_id" => nil, "master_id" => nil, "name" => nil, "type" => nil, "url" => nil}

  @create_user_attrs %{"icon_path" => "some icon_path", "language" => "some language", "name" => "some name", "notification_number" => 42, "point" => 42, "email" => "some2@email.com", "logout_fl" => true, "password" => "S1ome password"}
  @create_user_attrs2 %{"icon_path" => "some icon_path", "language" => "some language", "name" => "some sname", "notification_number" => 42, "point" => 42, "email" => "somes2@email.com", "logout_fl" => true, "password" => "S1ome password"}

  defp fixture_tournaments(num) do
    1..num
    |> Enum.map(fn n ->
      {:ok, user} =
        Map.new()
        |> Map.put("name", to_string(n) <> "name")
        |> Map.put("email", to_string(n) <> "@email.com")
        |> Map.put("password", "Password123")
        |> Accounts.create_user()
      {:ok, tournament} = Tournaments.create_tournament(%{@create_attrs|"master_id" => user.id})
      tournament
    end)
  end

  def fixture(:tournament) do
    {:ok, user} =
      %{"name" => "name", "email" => "e@mail.com", "password" => "Password123"}
      |> Accounts.create_user()
    {:ok, tournament} = Tournaments.create_tournament(%{@create_attrs|"master_id" => user.id})
    tournament
  end

  def fixture_tournament_incoming() do
    {:ok, user} =
      %{"name" => "name", "email" => "e@mail.com", "password" => "Password123"}
      |> Accounts.create_user()
    {:ok, tournament} = Tournaments.create_tournament(%{@create_incoming_attrs|"master_id" => user.id})
    tournament
  end

  def fixture(:user) do
    {:ok, _user} = Accounts.create_user(@create_user_attrs)
  end

  # FIXME: てきとう
  def fixture(:user2) do
    {:ok, _user} = Accounts.create_user(@create_user_attrs2)
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    setup [:create_tournament]

    test "index with valid data", %{conn: conn, tournament: tournament} do
      conn = get(conn, Routes.tournament_path(conn, :index))
      assert length(json_response(conn, 200)["data"]) == 1
    end
  end

  describe "get users for add assistant" do
    setup [:create_tournament]

    test "get_users_for_add_assistant/2 with valid data", %{conn: conn, tournament: tournament} do
      {:ok, user2} = fixture(:user)
      {:ok, user3} = fixture(:user2)
      inspect(user2)
      inspect(user3)
      user2_id = user2.id
      user3_id = user3.id

      conn = post(conn, Routes.relation_path(conn, :create), %{"relation" => %{"followee_id" => user2_id, "follower_id" => tournament.master_id}})
      assert json_response(conn, 200)["result"]
      conn = post(conn, Routes.relation_path(conn, :create), %{"relation" => %{"followee_id" => user3_id, "follower_id" => tournament.master_id}})
      assert json_response(conn, 200)["result"]

      conn = get(conn, Routes.tournament_path(conn, :get_users_for_add_assistant), user_id: tournament.master_id)
      assert json_response(conn, 200)["result"]
      json_response(conn, 200)["data"]
      |> Enum.each(fn user ->
        assert user["id"] == user2_id || user["id"] == user3_id
      end)
    end
  end

  describe "get tournaments by master id" do
    setup [:create_tournament]

    test "get_tournaments_by_master_id", %{conn: conn, tournament: tournament} do
      conn = get(conn, Routes.tournament_path(conn, :get_tournaments_by_master_id), %{user_id: tournament.master_id})
      json_response(conn, 200)
      |> Map.get("data")
      |> Enum.map(fn t ->
        assert t["id"] == tournament.id
      end)
      |> length()
      |> (fn len ->
        assert len  == 1
      end).()
    end
  end

  describe "get ongoing tournaments by master id" do

    test "get_ongoing_tournaments_by_master_id", %{conn: conn} do
      tournament = fixture_tournament_incoming()
      conn = post(conn, Routes.tournament_path(conn, :get_ongoing_tournaments_by_master_id), %{user_id: tournament.master_id})

      assert json_response(conn, 200)["result"]
      json_response(conn, 200)
      |> Map.get("data")
      |> Enum.map(fn t ->
        assert t["id"] == tournament.id
      end)
      |> length()
      |> (fn len ->
        assert len == 1
      end).()
    end
  end

  describe "get planned tournaments by master id" do

    test "get_planned_tournaments_by_master_id", %{conn: conn} do
      tournament = fixture_tournament_incoming()
      conn = get(conn, Routes.tournament_path(conn, :get_planned_tournaments_by_master_id), user_id: tournament.master_id)

      {:ok, user} = fixture(:user)
      %{
        "rank" => 0,
        "tournament_id" => tournament.id,
        "user_id" => user.id
      }
      |> Tournaments.create_entrant()

      json_response(conn, 200)
      |> Map.get("tournaments")
      |> Enum.map(fn t ->
        assert t["id"] == tournament.id
      end)
      |> length()
      |> (fn len ->
        assert len == 1
      end).()
    end
  end

  describe "get tournament by url" do
    setup [:create_tournament]

    test "get tournament by url", %{conn: conn, tournament: tournament} do
      conn = get(conn, Routes.tournament_path(conn, :get_tournament_by_url), %{url: tournament.url})
      t = json_response(conn, 200)["data"]
      assert t["id"] == tournament.id
    end
  end

  describe "get tournament pid by tournament id" do
    setup [:create_tournament]

    test "get tournament pid by tournament id works fine with valid data", %{conn: conn, tournament: tournament} do
      pid = "0.111.0"
      conn = post(conn, Routes.tournament_path(conn, :register_pid_of_start_notification), %{tournament_id: tournament.id, pid: pid})
      conn = get(conn, Routes.tournament_path(conn, :get_pid), %{tournament_id: tournament.id})

      assert json_response(conn, 200)["pid"] == pid
    end
  end

  describe "get pid" do
    setup [:create_tournament]

    test "get pid", %{conn: conn, tournament: _tournament} do
      {:ok, user} =
        %{"name" => "namasdfe", "email" => "easdf@mail.com", "password" => "Password123"}
        |> Accounts.create_user()

      pid = "0.111.0"

      {:ok, tournament} =
        @create_attrs
        |> Map.put("master_id", user.id)
        |> Map.put("start_notification_pid", pid)
        |> Tournaments.create_tournament()

      conn = get(conn, Routes.tournament_path(conn, :get_pid), %{tournament_id: tournament.id})
      assert json_response(conn, 200)["pid"] == pid
    end
  end

  describe "create tournament" do
    test "renders tournament when data is valid", %{conn: conn} do
      {:ok, user} = fixture(:user)
      attrs = Map.put(@create_attrs, "master_id", user.id)
      conn = post(conn, Routes.tournament_path(conn, :create), %{tournament: attrs, file: ""})
      assert %{"id" => id} = json_response(conn, 200)["data"]

      conn = post(conn, Routes.tournament_path(conn, :show, %{"tournament_id" => id}))

      assert _tournament = json_response(conn, 200)["data"]
    end

    test "renders errors when data is mostly nil", %{conn: conn} do
      conn = post(conn, Routes.tournament_path(conn, :create), tournament: @invalid_attrs, file: "")
      assert json_response(conn, 200)["error"] == "join parameter is nil"
      refute json_response(conn, 200)["result"]
    end

    test "renders error when data is invalid", %{conn: conn} do
      attrs = %{
        "capacity" => 42,
        "deadline" => "2010-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2010-04-17T14:00:00Z",
        "master_id" => -1,
        "name" => "some name",
        "type" => 42,
        "join" => "true",
        "url" => "some url",
        "platform_id" => 1
      }
      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: "")
      assert json_response(conn, 200)["error"] == "Undefined User"
      refute json_response(conn, 200)["result"]
    end
  end

  describe "get tournament" do
    setup [:create_tournament]

    test "get tournament with valid data", %{conn: conn, tournament: tournament} do
      conn = get(conn, Routes.tournament_path(conn, :show), %{"tournament_id" => tournament.id})
      assert json_response(conn, 200)["result"]
    end

    test "get finished tournament", %{conn: conn, tournament: tournament} do
      entrants = create_entrants(2, tournament.id)
      entrant = hd(entrants)

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})
      conn = post(conn, Routes.tournament_path(conn, :delete_loser), tournament: %{"tournament_id" => tournament.id, "loser_list" => [entrant.user_id]})
      conn = post(conn, Routes.tournament_path(conn, :finish), %{"tournament_id" => tournament.id, "user_id" => tournament.master_id})
      conn = get(conn, Routes.tournament_path(conn, :show), %{"tournament_id" => tournament.id})

      assert json_response(conn, 200)["result"]
      assert TournamentProgress.get_duplicate_users(tournament.id) == []
    end

    test "cannot get a tournament which does not exist", %{conn: conn, tournament: _tournament} do
      conn = get(conn, Routes.tournament_path(conn, :show), %{"tournament_id" => -1})
      refute json_response(conn, 200)["result"]
    end
  end

  describe "home" do
    test "normal home", %{conn: conn} do
      {:ok, user} = fixture(:user)
      attrs = %{
        "capacity" => 42,
        "deadline" => "2040-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2040-04-17T14:00:00Z",
        "master_id" => user.id,
        "name" => "some name",
        "type" => 42,
        "join" => "true",
        "url" => "some url",
        "platform_id" => 1
      }
      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: "")
      id = json_response(conn, 200)["data"]["id"]
      date_offset =
        Timex.now()
        |> Timex.add(Timex.Duration.from_days(1))

      get(conn, Routes.tournament_path(conn, :home), date_offset: date_offset, offset: 0)
      |> json_response(200)
      |> Map.get("data")
      |> Enum.map(fn tournament ->
        assert tournament["id"] == id
      end)
      |> length()
      |> (fn len ->
        assert len == 1
      end).()
    end

    test "fav filtered", %{conn: conn} do
      {:ok, user1} = fixture(:user)
      {:ok, user2} = fixture(:user2)
      attrs = %{
        "capacity" => 42,
        "deadline" => "2040-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2040-04-17T14:00:00Z",
        "master_id" => user1.id,
        "name" => "some name",
        "type" => 42,
        "join" => "true",
        "url" => "some url",
        "platform_id" => 1
      }
      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: "")
      id = json_response(conn, 200)["data"]["id"]
      Relations.create_relation(%{"follower_id" => user2.id, "followee_id" => user1.id})

      get(conn, Routes.tournament_path(conn, :home), filter: "fav", user_id: user2.id)
      |> json_response(200)
      |> Map.get("data")
      |> Enum.map(fn tournament ->
        assert tournament["id"] == id
      end)
      |> length()
      |> (fn len ->
        assert len == 1
      end).()
    end

    test "plan filtered", %{conn: conn} do
      {:ok, user} = fixture(:user)
      attrs = %{
        "capacity" => 42,
        "deadline" => "2040-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2040-04-17T14:00:00Z",
        "master_id" => user.id,
        "name" => "some name",
        "type" => 42,
        "join" => "true",
        "url" => "some url",
        "platform_id" => 1
      }
      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: "")
      id = json_response(conn, 200)["data"]["id"]

      get(conn, Routes.tournament_path(conn, :home), filter: "plan", user_id: user.id)
      |> json_response(200)
      |> Map.get("data")
      |> Enum.map(fn tournament ->
        assert tournament["id"] == id
      end)
      |> length()
      |> (fn len ->
        assert len == 1
      end).()
    end

    test "entry filtered", %{conn: conn} do
      {:ok, user} = fixture(:user)
      attrs = %{
        "capacity" => 42,
        "deadline" => "2040-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2040-04-17T14:00:00Z",
        "master_id" => user.id,
        "name" => "some name",
        "type" => 42,
        "join" => "true",
        "url" => "some url",
        "platform_id" => 1
      }
      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: "")
      id = json_response(conn, 200)["data"]["id"]

      get(conn, Routes.tournament_path(conn, :home), filter: "entry", user_id: user.id)
      |> json_response(200)
      |> Map.get("data")
      |> Enum.map(fn tournament ->
        assert tournament["id"] == id
      end)
      |> length()
      |> (fn len ->
        assert len == 1
      end).()
    end
  end

  describe "update tournament" do
    setup [:create_tournament]

    test "works", %{conn: conn, tournament: tournament} do
      conn = put(conn, Routes.tournament_path(conn, :update), %{"tournament_id" => tournament.id, "tournament" => @update_attrs})
      json_response(conn, 200)
      |> Map.get("data")
      |> (fn t ->
        assert t["id"] == tournament.id
        assert t["capacity"] == @update_attrs["capacity"]
      end).()
    end
  end

  describe "delete tournament" do
    setup [:create_tournament]

    test "deletes chosen tournament", %{conn: conn, tournament: tournament} do
      conn = post(conn, Routes.tournament_path(conn, :delete, %{"tournament_id" => tournament.id}))
      assert response(conn, 200)

      conn = get(conn, Routes.tournament_path(conn, :show, %{"tournament_id" => tournament.id}))
      assert response(conn, 200)
    end
  end

  describe "participating tournaments" do
    test "works", %{conn: conn} do
      fixture_tournaments(3)
    end
  end

  describe "start tournament" do
    setup [:create_tournament]

    test "start a tournament with valid data", %{conn: conn, tournament: tournament} do
      _entrants = create_entrants(12, tournament.id)
      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

      assert json_response(conn, 200)["data"]["match_list"] |> is_list()
      assert Tournaments.get_entrants(tournament.id)
        |> Enum.map(fn x -> x.rank end)
        |> Enum.filter(fn x -> x == 8 end)
        |> length()
        |> Kernel.==(4)
    end
  end

  describe "get entrants" do
    setup [:create_tournament]

    test "get entrants", %{conn: conn, tournament: tournament} do
      entrants = create_entrants(8, tournament.id)
      entrant_id_list = Enum.map(entrants, fn entrant -> entrant.id end)
      conn = get(conn, Routes.tournament_path(conn, :get_entrants), tournament_id: tournament.id)

      json_response(conn, 200)["data"]
      |> Enum.map(fn entrant ->
        assert Enum.member?(entrant_id_list, entrant["id"])
      end)
      |> length()
      |> (fn len ->
        assert len == length(entrants)
      end).()
    end
  end

  describe "get opponent" do
    setup [:create_tournament]

    test "get an opponent of a started tournament with valid data", %{conn: conn, tournament: tournament} do
      entrants = create_entrants(8, tournament.id)

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})
      conn = get(conn, Routes.tournament_path(conn, :get_opponent), %{"tournament_id" => tournament.id, "user_id" => hd(entrants).user_id})

      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["opponent"]
    end
  end

  describe "get fighting users" do
    setup [:create_tournament]

    test "get fighting users", %{conn: conn, tournament: tournament} do
      entrants = create_entrants(8, tournament.id)
      player = hd(entrants)

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})
      conn = get(conn, Routes.tournament_path(conn, :get_opponent), %{"tournament_id" => tournament.id, "user_id" => player.user_id})

      opponent = json_response(conn, 200)["opponent"]
      conn = get(conn, Routes.tournament_path(conn, :get_fighting_users), tournament_id: tournament.id)
      assert json_response(conn, 200)["data"] == []

      conn = post(conn, Routes.tournament_path(conn, :start_match), user_id: player.user_id, tournament_id: tournament.id)
      assert json_response(conn, 200)["result"]
      conn = get(conn, Routes.tournament_path(conn, :get_fighting_users), tournament_id: tournament.id)
      assert length(json_response(conn, 200)["data"]) == 1

      conn = post(conn, Routes.tournament_path(conn, :start_match), user_id: opponent["id"], tournament_id: tournament.id)
      assert json_response(conn, 200)["result"]
      conn = get(conn, Routes.tournament_path(conn, :get_fighting_users), tournament_id: tournament.id)
      assert length(json_response(conn, 200)["data"]) == 2

      conn = post(conn, Routes.tournament_path(conn, :claim_win), opponent_id: opponent["id"], user_id: player.user_id, tournament_id: tournament.id)
      conn = post(conn, Routes.tournament_path(conn, :claim_lose), opponent_id: player.user_id, user_id: opponent["id"], tournament_id: tournament.id)
      conn = get(conn, Routes.tournament_path(conn, :get_fighting_users), tournament_id: tournament.id)
      assert length(json_response(conn, 200)["data"]) == 0
    end
  end

  describe "get waiting users" do
    setup [:create_tournament]

    test "get waiting users", %{conn: conn, tournament: tournament} do
      entrants = create_entrants(8, tournament.id)
      player = hd(entrants)

      conn =
        conn
        |> post(Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})
        |> get(Routes.tournament_path(conn, :get_opponent), %{"tournament_id" => tournament.id, "user_id" => player.user_id})

      opponent = json_response(conn, 200)["opponent"]
      conn = get(conn, Routes.tournament_path(conn, :get_waiting_users), tournament_id: tournament.id)
      json_response(conn, 200)
      |> Map.get("data")
      |> length()
      |> (fn len ->
        assert len == length(entrants)
      end).()

      conn = post(conn, Routes.tournament_path(conn, :start_match), user_id: player.user_id, tournament_id: tournament.id)
      assert json_response(conn, 200)["result"]
      conn = get(conn, Routes.tournament_path(conn, :get_waiting_users), tournament_id: tournament.id)
      assert length(json_response(conn, 200)["data"]) == length(entrants) - 1

      conn = post(conn, Routes.tournament_path(conn, :start_match), user_id: opponent["id"], tournament_id: tournament.id)
      assert json_response(conn, 200)["result"]
      conn = get(conn, Routes.tournament_path(conn, :get_waiting_users), tournament_id: tournament.id)
      assert length(json_response(conn, 200)["data"]) == length(entrants) - 2

      conn = post(conn, Routes.tournament_path(conn, :claim_win), opponent_id: opponent["id"], user_id: player.user_id, tournament_id: tournament.id)
      conn = post(conn, Routes.tournament_path(conn, :claim_lose), opponent_id: player.user_id, user_id: opponent["id"], tournament_id: tournament.id)
      conn = post(conn, Routes.tournament_path(conn, :delete_loser), tournament: %{tournament_id: tournament.id, loser_list: [opponent["id"]]})
      conn = get(conn, Routes.tournament_path(conn, :get_waiting_users), tournament_id: tournament.id)
      assert length(json_response(conn, 200)["data"]) == length(entrants) - 1
    end
  end

  describe "register pid of start notification" do
    setup [:create_tournament]

    test "register pid of start notification with valid data", %{conn: conn, tournament: tournament} do
      pid = "0.100.0"
      conn = post(conn, Routes.tournament_path(conn, :register_pid_of_start_notification), %{tournament_id: tournament.id, pid: pid})
      assert json_response(conn, 200)
      assert json_response(conn, 200)["result"]

      # Check tournament pid has been stored
      t = Tournaments.get_tournament!(tournament.id)
      assert t.start_notification_pid == pid
    end
  end

  describe "test duplicate claim members" do
    setup [:create_tournament]

    test "get duplicate claim members", %{conn: conn, tournament: tournament} do
      entrants = create_entrants(17, tournament.id)
      player = hd(entrants)

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})
      conn = get(conn, Routes.tournament_path(conn, :get_opponent), %{"tournament_id" => tournament.id, "user_id" => player.user_id})

      response = json_response(conn, 200)
      cond do
        !is_nil(response["opponent"]) -> true
        is_nil(response["opponent"]) and !is_nil(response["wait"]) -> false
        true -> assert false, "it must not be true"
      end
      |> if do
        opponent = response["opponent"]
        conn = post(conn, Routes.tournament_path(conn, :start_match), user_id: player.user_id, tournament_id: tournament.id)
        conn = post(conn, Routes.tournament_path(conn, :start_match), user_id: opponent["id"], tournament_id: tournament.id)
        conn = post(conn, Routes.tournament_path(conn, :claim_win), opponent_id: opponent["id"], user_id: player.user_id, tournament_id: tournament.id)
        conn = post(conn, Routes.tournament_path(conn, :claim_win), opponent_id: player.user_id, user_id: opponent["id"], tournament_id: tournament.id)

        tournament.id
        |> TournamentProgress.get_duplicate_users()
        |> Kernel.==([opponent["id"], player.user_id])
        |> Kernel.||(
          tournament.id
          |> TournamentProgress.get_duplicate_users()
          |> Kernel.==([player.user_id, opponent["id"]])
        )
        |> (fn bool ->
          assert bool
        end).()

        conn
        |> get(Routes.tournament_path(conn, :get_duplicate_claim_members), tournament_id: tournament.id)
        |> json_response(200)
        |> Map.get("data")
        |> Enum.each(fn user ->
          user["id"]
          |> Kernel.==(player.user_id)
          |> Kernel.||(user["id"] == opponent["id"])
          |> (fn bool ->
            assert bool
          end).()
        end)
      else
        Logger.info("opponent is nil in 'test duplicate claim members'")
      end
    end
  end

  describe "test trim of players" do
    setup [:create_tournament]

    test "trim of players", %{conn: conn, tournament: tournament} do
      entrants = create_entrants(17, tournament.id)
      player = hd(entrants)

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})
      match_list = json_response(conn, 200)["data"]["match_list"]

      tournament.id
      |> TournamentProgress.get_match_list_with_fight_result()
      |> hd()
      |> elem(1)
      |> Tournaments.match_list_length()
      |> (fn len ->
        assert len == 17
      end).()
      conn = get(conn, Routes.tournament_path(conn, :get_opponent), %{"tournament_id" => tournament.id, "user_id" => player.user_id})

      response = json_response(conn, 200)
      cond do
        !is_nil(response["opponent"]) -> true
        is_nil(response["opponent"]) and !is_nil(response["wait"]) -> false
        true -> assert false, "it must not be true"
      end
      |> if do
        opponent = response["opponent"]
        conn = post(conn, Routes.tournament_path(conn, :start_match), user_id: player.user_id, tournament_id: tournament.id)
        conn = post(conn, Routes.tournament_path(conn, :start_match), user_id: opponent["id"], tournament_id: tournament.id)
        conn = post(conn, Routes.tournament_path(conn, :claim_win), opponent_id: opponent["id"], user_id: player.user_id, tournament_id: tournament.id)
        conn = post(conn, Routes.tournament_path(conn, :claim_lose), opponent_id: player.user_id, user_id: opponent["id"], tournament_id: tournament.id)
        conn = post(conn, Routes.tournament_path(conn, :delete_loser), tournament: %{"tournament_id" => tournament.id, "loser_list" => [opponent["id"]]})

        tournament.id
        |> TournamentProgress.get_match_list_with_fight_result()
        |> hd()
        |> elem(1)
        |> Tournaments.match_list_length()
        |> (fn len ->
          assert len == 16
        end).()
      else
        Logger.warn("opponent is nil in 'test trim of players'")
      end
    end
  end

  defp create_tournament(_) do
    tournament = fixture(:tournament)
    %{tournament: tournament}
  end

  # 複数の参加者作成用関数
  defp create_entrants(num, tournament_id) do
    Enum.map(1 .. num, fn x ->
      {:ok, user} =
        %{"name" => "name" <> to_string(x), "email" => "e" <> to_string(x) <> "@mail.com", "password" => "Password123"}
        |> Accounts.create_user()
      {:ok, entrant} =
        %{@entrant_create_attrs | "tournament_id" => tournament_id, "user_id" => user.id}
        |> Tournaments.create_entrant()
      entrant
    end)
  end
end

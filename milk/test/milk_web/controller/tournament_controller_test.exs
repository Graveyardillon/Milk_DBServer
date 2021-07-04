defmodule MilkWeb.TournamentControllerTest do
  use MilkWeb.ConnCase
  use Milk.Common.Fixtures

  import Ecto.Query, warn: false

  alias Milk.{
    Accounts,
    Platforms,
    Relations,
    Repo,
    TournamentProgress,
    Tournaments
  }

  alias Milk.Accounts.ActionHistory

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
    "game_name" => "gm nm",
    "type" => 1,
    "join" => "true",
    "url" => "some url",
    "password" => "Password123",
    "platform" => 1
  }

  @create_incoming_attrs %{
    "capacity" => 42,
    "deadline" => "2100-04-17T14:00:00Z",
    "description" => "some description",
    "event_date" => "2100-04-17T14:00:00Z",
    "master_id" => 42,
    "name" => "some name",
    "type" => 1,
    "join" => "true",
    "url" => "some url",
    "platform" => 1
  }

  @update_attrs %{
    "capacity" => 4200,
    "url" => "updated url"
  }

  @invalid_attrs %{
    "capacity" => nil,
    "deadline" => nil,
    "description" => nil,
    "event_date" => nil,
    "game_id" => nil,
    "master_id" => nil,
    "name" => nil,
    "type" => nil,
    "url" => nil
  }

  defp fixture_tournaments(num) do
    1..num
    |> Enum.map(fn n ->
      {:ok, user} =
        Map.new()
        |> Map.put("name", to_string(n) <> "name")
        |> Map.put("email", to_string(n) <> "@email.com")
        |> Map.put("password", "Password123")
        |> Accounts.create_user()

      {:ok, tournament} = Tournaments.create_tournament(%{@create_attrs | "master_id" => user.id})
      tournament
    end)
  end

  def fixture_tournament_incoming() do
    user = fixture_user(num: 0)

    {:ok, tournament} =
      Tournaments.create_tournament(%{@create_incoming_attrs | "master_id" => user.id})

    tournament
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "get users for add assistant" do
    setup [:create_tournament]

    test "get_users_for_add_assistant/2 with valid data", %{conn: conn, tournament: tournament} do
      user2 = fixture_user(num: 2)
      user3 = fixture_user(num: 3)
      inspect(user2, charlists: false)
      inspect(user3, charlists: false)
      user2_id = user2.id
      user3_id = user3.id

      conn =
        post(conn, Routes.relation_path(conn, :create), %{
          "relation" => %{"followee_id" => user2_id, "follower_id" => tournament.master_id}
        })

      assert json_response(conn, 200)["result"]

      conn =
        post(conn, Routes.relation_path(conn, :create), %{
          "relation" => %{"followee_id" => user3_id, "follower_id" => tournament.master_id}
        })

      assert json_response(conn, 200)["result"]

      conn =
        get(conn, Routes.tournament_path(conn, :get_users_for_add_assistant),
          user_id: tournament.master_id
        )

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
      conn =
        get(conn, Routes.tournament_path(conn, :get_tournaments_by_master_id), %{
          user_id: tournament.master_id
        })

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

    test "including assistant", %{conn: conn, tournament: tournament} do
      user = fixture_user()

      conn =
        post(conn, Routes.assistant_path(conn, :create),
          assistant: %{tournament_id: tournament.id, user_id: [user.id]}
        )

      conn =
        get(conn, Routes.tournament_path(conn, :get_tournaments_by_master_id), %{user_id: user.id})

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

    test "including both", %{conn: conn} do
      tournament = fixture_tournament(num: 2)
      tournament2 = fixture_tournament(num: 1)

      conn =
        post(conn, Routes.assistant_path(conn, :create),
          assistant: %{tournament_id: tournament2.id, user_id: [tournament.master_id]}
        )

      conn =
        get(conn, Routes.tournament_path(conn, :get_tournaments_by_master_id), %{
          user_id: tournament.master_id
        })

      json_response(conn, 200)
      |> Map.get("data")
      |> Enum.map(fn t ->
        assert t["id"] == tournament.id || t["id"] == tournament2.id
      end)
      |> length()
      |> (fn len ->
            assert len == 2
          end).()
    end
  end

  describe "get ongoing tournaments by master id" do
    test "get_ongoing_tournaments_by_master_id", %{conn: conn} do
      tournament = fixture_tournament_incoming()

      conn =
        post(conn, Routes.tournament_path(conn, :get_ongoing_tournaments_by_master_id), %{
          user_id: tournament.master_id
        })

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

      conn =
        get(conn, Routes.tournament_path(conn, :get_planned_tournaments_by_master_id),
          user_id: tournament.master_id
        )

      user = fixture_user(num: 1)

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
      conn =
        get(conn, Routes.tournament_path(conn, :get_tournament_by_url), %{url: tournament.url})

      t = json_response(conn, 200)["data"]
      assert t["id"] == tournament.id
    end
  end

  describe "create tournament" do
    test "renders tournament when data is valid (and scores gain in action history)", %{
      conn: conn
    } do
      user = fixture_user()
      attrs = Map.put(@create_attrs, "master_id", user.id)
      conn = post(conn, Routes.tournament_path(conn, :create), %{tournament: attrs, file: ""})
      assert %{"id" => id} = json_response(conn, 200)["data"]

      conn = post(conn, Routes.tournament_path(conn, :show, %{"tournament_id" => id}))

      assert tournament = json_response(conn, 200)["data"]
      refute json_response(conn, 200)["is_log"]

      json_response(conn, 200)
      |> Map.get("data")
      |> (fn tournament ->
            assert tournament["capacity"] == @create_attrs["capacity"]
            assert tournament["description"] == @create_attrs["description"]
            assert tournament["game_name"] == @create_attrs["game_name"]
            assert tournament["has_password"]
            assert tournament["master_id"] == user.id
            assert tournament["name"] == @create_attrs["name"]
            assert tournament["platform"] == @create_attrs["platform"]
            assert tournament["type"] == @create_attrs["type"]
            assert tournament["url"] == @create_attrs["url"]
          end).()

      ActionHistory
      |> where([ah], ah.user_id == ^tournament["master_id"])
      |> Repo.all()
      |> Enum.map(fn action_history ->
        assert action_history.game_name == tournament["game_name"]
        assert action_history.user_id == tournament["master_id"]
        assert action_history.gain == 7
      end)
      |> length()
      |> (fn len ->
            assert len == 1
          end).()
    end

    test "renders errors when data is mostly nil", %{conn: conn} do
      conn =
        post(conn, Routes.tournament_path(conn, :create), tournament: @invalid_attrs, file: "")

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
        "type" => 1,
        "join" => "true",
        "url" => "some url",
        "platform" => 1
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

      json_response(conn, 200)
      |> Map.get("data")
      |> (fn data ->
            assert data["id"] == tournament.id
            assert data["name"] == tournament.name
            assert data["thumbnail_path"] == tournament.thumbnail_path
            assert data["game_id"] == tournament.game_id
            assert data["game_name"] == tournament.game_name
            # assert data["event_date"] == tournament.event_date
            # assert data["start_recruiting"] == tournament.start_recruiting
            # assert data["deadline"] == tournament.deadline
            assert data["type"] == tournament.type
            # assert data["platform"] == tournament.platform
            assert is_nil(data["password"])
            assert data["capacity"] == tournament.capacity
            assert data["master_id"] == tournament.master_id
            assert data["url"] == tournament.url
            assert data["is_started"] == tournament.is_started
          end).()
    end

    test "get finished tournament", %{conn: conn, tournament: tournament} do
      entrants = create_entrants(2, tournament.id)
      entrant = hd(entrants)

      conn =
        post(conn, Routes.tournament_path(conn, :start),
          tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id}
        )

      conn =
        post(conn, Routes.tournament_path(conn, :delete_loser),
          tournament: %{"tournament_id" => tournament.id, "loser_list" => [entrant.user_id]}
        )

      conn =
        post(conn, Routes.tournament_path(conn, :finish), %{
          "tournament_id" => tournament.id,
          "user_id" => tournament.master_id
        })

      conn = get(conn, Routes.tournament_path(conn, :show), %{"tournament_id" => tournament.id})

      assert json_response(conn, 200)["result"]

      json_response(conn, 200)
      |> Map.get("data")
      |> (fn data ->
            assert data["tournament_id"] == tournament.id
            assert data["name"] == tournament.name
            # assert data["thumbnail_path"] == tournament.thumbnail_path
            assert data["game_id"] == tournament.game_id
            assert data["game_name"] == tournament.game_name
            # assert data["event_date"] == tournament.event_date
            # assert data["start_recruiting"] == tournament.start_recruiting
            # assert data["deadline"] == tournament.deadline
            assert data["type"] == tournament.type
            # assert data["platform"] == tournament.platform
            assert is_nil(data["password"])
            assert data["capacity"] == tournament.capacity
            assert data["master_id"] == tournament.master_id
            assert data["url"] == tournament.url
          end).()

      assert TournamentProgress.get_duplicate_users(tournament.id) == []
    end

    test "cannot get a tournament which does not exist", %{conn: conn, tournament: _tournament} do
      conn = get(conn, Routes.tournament_path(conn, :show), %{"tournament_id" => -1})
      refute json_response(conn, 200)["result"]
    end

    test "get tournament with user_id", %{conn: conn, tournament: tournament} do
      conn =
        get(conn, Routes.tournament_path(conn, :show), %{
          "user_id" => tournament.master_id,
          "tournament_id" => tournament.id
        })

      assert json_response(conn, 200)["result"]

      json_response(conn, 200)
      |> Map.get("data")
      |> (fn data ->
            assert data["id"] == tournament.id
            assert data["name"] == tournament.name
            assert data["thumbnail_path"] == tournament.thumbnail_path
            assert data["game_id"] == tournament.game_id
            assert data["game_name"] == tournament.game_name
            # assert data["event_date"] == tournament.event_date
            # assert data["start_recruiting"] == tournament.start_recruiting
            # assert data["deadline"] == tournament.deadline
            assert data["type"] == tournament.type
            # assert data["platform"] == tournament.platform
            assert is_nil(data["password"])
            assert data["capacity"] == tournament.capacity
            assert data["master_id"] == tournament.master_id
            assert data["url"] == tournament.url
            assert data["is_started"] == tournament.is_started
          end).()

      ActionHistory
      |> where([ah], ah.user_id == ^tournament.master_id)
      |> Repo.all()
      |> Enum.map(fn action_history ->
        assert action_history.game_name == tournament.game_name
        assert action_history.user_id == tournament.master_id
        assert action_history.gain == 1
      end)
      |> length()
      |> (fn len ->
            assert len == 1
          end).()
    end

    test "get tournament log with user_id", %{conn: conn, tournament: tournament} do
      entrants = create_entrants(2, tournament.id)
      entrant = hd(entrants)

      conn =
        post(conn, Routes.tournament_path(conn, :start),
          tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id}
        )

      conn =
        post(conn, Routes.tournament_path(conn, :delete_loser),
          tournament: %{"tournament_id" => tournament.id, "loser_list" => [entrant.user_id]}
        )

      conn =
        post(conn, Routes.tournament_path(conn, :finish), %{
          "tournament_id" => tournament.id,
          "user_id" => tournament.master_id
        })

      conn =
        get(conn, Routes.tournament_path(conn, :show), %{
          "user_id" => tournament.master_id,
          "tournament_id" => tournament.id
        })

      assert json_response(conn, 200)["result"]

      json_response(conn, 200)
      |> Map.get("data")
      |> (fn data ->
            assert data["tournament_id"] == tournament.id
            assert data["name"] == tournament.name
            # assert data["thumbnail_path"] == tournament.thumbnail_path
            assert data["game_id"] == tournament.game_id
            assert data["game_name"] == tournament.game_name
            # assert data["event_date"] == tournament.event_date
            # assert data["start_recruiting"] == tournament.start_recruiting
            # assert data["deadline"] == tournament.deadline
            assert data["type"] == tournament.type
            # assert data["platform"] == tournament.platform
            assert is_nil(data["password"])
            assert data["capacity"] == tournament.capacity
            assert data["master_id"] == tournament.master_id
            assert data["url"] == tournament.url
          end).()

      ActionHistory
      |> where([ah], ah.user_id == ^tournament.master_id)
      |> Repo.all()
      |> Enum.map(fn action_history ->
        assert action_history.game_name == tournament.game_name
        assert action_history.user_id == tournament.master_id
        assert action_history.gain == 1
      end)
      |> length()
      |> (fn len ->
            assert len == 1
          end).()
    end

    test "cannot get action history", %{conn: conn, tournament: tournament} do
      get(conn, Routes.tournament_path(conn, :show), %{"tournament_id" => tournament.id})

      ActionHistory
      |> where([ah], ah.user_id == ^tournament.master_id)
      |> Repo.all()
      |> length()
      |> (fn len ->
            assert len == 0
          end).()
    end
  end

  describe "home" do
    test "normal home", %{conn: conn} do
      user = fixture_user()

      attrs = %{
        "capacity" => 42,
        "deadline" => "2040-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2040-04-17T14:00:00Z",
        "master_id" => user.id,
        "name" => "some name",
        "type" => 1,
        "join" => "true",
        "url" => "some url",
        "platform" => 1
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

    test "blocked user", %{conn: conn} do
      user = fixture_user()

      attrs = %{
        "capacity" => 42,
        "deadline" => "2040-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2040-04-17T14:00:00Z",
        "master_id" => user.id,
        "name" => "some name",
        "type" => 1,
        "join" => "true",
        "url" => "some url",
        "platform" => 1
      }

      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: "")
      tournament = json_response(conn, 200)["data"]

      Relations.block(user.id, tournament["master_id"])

      date_offset =
        Timex.now()
        |> Timex.add(Timex.Duration.from_days(1))

      get(conn, Routes.tournament_path(conn, :home),
        user_id: user.id,
        date_offset: date_offset,
        offset: 0
      )
      |> json_response(200)
      |> Map.get("data")
      |> length()
      |> (fn len ->
            assert len == 0
          end).()
    end

    test "fav filtered", %{conn: conn} do
      user1 = fixture_user(num: 1)
      user2 = fixture_user(num: 2)

      attrs = %{
        "capacity" => 42,
        "deadline" => "2040-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2040-04-17T14:00:00Z",
        "master_id" => user1.id,
        "name" => "some name",
        "type" => 1,
        "join" => "true",
        "url" => "some url",
        "platform" => 1
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
      user = fixture_user()

      attrs = %{
        "capacity" => 42,
        "deadline" => "2040-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2040-04-17T14:00:00Z",
        "master_id" => user.id,
        "name" => "some name",
        "type" => 1,
        "join" => "true",
        "url" => "some url",
        "platform" => 1
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
      user = fixture_user()

      attrs = %{
        "capacity" => 42,
        "deadline" => "2040-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2040-04-17T14:00:00Z",
        "master_id" => user.id,
        "name" => "some name",
        "type" => 1,
        "join" => "true",
        "url" => "some url",
        "platform" => 1
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

    test "search", %{conn: conn} do
      user = fixture_user()

      attrs = %{
        "capacity" => 42,
        "deadline" => "2040-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2040-04-17T14:00:00Z",
        "master_id" => user.id,
        "name" => "some name",
        "type" => 1,
        "join" => "true",
        "url" => "some url",
        "platform" => 1
      }

      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: "")
      id = json_response(conn, 200)["data"]["id"]

      conn = get(conn, Routes.tournament_path(conn, :search), user_id: nil, text: "some")

      json_response(conn, 200)
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
      conn =
        put(conn, Routes.tournament_path(conn, :update), %{
          "tournament_id" => tournament.id,
          "tournament" => @update_attrs
        })

      json_response(conn, 200)
      |> Map.get("data")
      |> (fn t ->
            assert t["id"] == tournament.id
            assert t["capacity"] == @update_attrs["capacity"]
            assert t["url"] == @update_attrs["url"]
          end).()
    end

    test "works with foreign key", %{conn: conn, tournament: tournament} do
      attrs = %{
        "platform" => 2
      }

      conn =
        put(conn, Routes.tournament_path(conn, :update), %{
          "tournament_id" => tournament.id,
          "tournament" => attrs
        })

      json_response(conn, 200)
      |> Map.get("data")
      |> (fn t ->
            assert t["platform"] == attrs["platform"]
            assert t["id"] == tournament.id
          end).()
    end
  end

  describe "delete tournament" do
    setup [:create_tournament]

    test "deletes chosen tournament", %{conn: conn, tournament: tournament} do
      conn =
        post(conn, Routes.tournament_path(conn, :delete, %{"tournament_id" => tournament.id}))

      assert response(conn, 200)

      conn = get(conn, Routes.tournament_path(conn, :show, %{"tournament_id" => tournament.id}))
      assert response(conn, 200)
    end
  end

  describe "participating tournaments" do
    test "works", %{conn: conn} do
      user = fixture_user()

      tournaments = fixture_tournaments(3)

      Enum.each(tournaments, fn tournament ->
        Map.new()
        |> Map.put("rank", 0)
        |> Map.put("tournament_id", tournament.id)
        |> Map.put("user_id", user.id)
        |> Tournaments.create_entrant()
      end)

      tournament_id_list =
        Enum.map(tournaments, fn tournament ->
          tournament.id
        end)

      conn =
        get(
          conn,
          Routes.tournament_path(conn, :participating_tournaments, %{
            "user_id" => user.id,
            "offset" => 0
          })
        )

      json_response(conn, 200)
      |> Map.get("data")
      |> Enum.map(fn tournament ->
        assert Enum.member?(tournament_id_list, tournament["id"])
      end)
      |> length()
      |> (fn len ->
            assert len == 3
          end).()

      conn =
        get(
          conn,
          Routes.tournament_path(conn, :participating_tournaments, %{"user_id" => user.id})
        )

      json_response(conn, 200)
      |> Map.get("data")
      |> Enum.map(fn tournament ->
        assert Enum.member?(tournament_id_list, tournament["id"])
      end)
      |> length()
      |> (fn len ->
            assert len == 3
          end).()

      conn =
        get(
          conn,
          Routes.tournament_path(conn, :participating_tournaments, %{
            "user_id" => user.id,
            "offset" => 1
          })
        )

      json_response(conn, 200)
      |> Map.get("data")
      |> Enum.map(fn tournament ->
        assert Enum.member?(tournament_id_list, tournament["id"])
      end)
      |> length()
      |> (fn len ->
            assert len == 2
          end).()
    end
  end

  describe "relevant" do
    setup [:create_tournament]

    test "works", %{conn: conn, tournament: tournament} do
      tournaments = fixture_tournaments(3)
      assistant_tournament = fixture_tournament(num: 999)

      conn =
        post(conn, Routes.assistant_path(conn, :create),
          assistant: %{tournament_id: assistant_tournament.id, user_id: [tournament.master_id]}
        )

      Enum.each(tournaments, fn t ->
        Map.new()
        |> Map.put("rank", 0)
        |> Map.put("tournament_id", t.id)
        |> Map.put("user_id", tournament.master_id)
        |> Tournaments.create_entrant()
      end)

      tournament_id_list =
        tournaments
        |> Enum.map(fn tournament ->
          tournament.id
        end)
        |> Enum.concat([tournament.id])
        |> Enum.concat([assistant_tournament.id])

      conn =
        get(conn, Routes.tournament_path(conn, :relevant, %{"user_id" => tournament.master_id}))

      json_response(conn, 200)
      |> Map.get("data")
      |> Enum.map(fn tournament ->
        assert Enum.member?(tournament_id_list, tournament["id"])
      end)
      |> length()
      |> (fn len ->
            assert len == length(tournament_id_list)
          end).()
    end
  end

  describe "is able to join" do
    test "works", %{conn: conn} do
      user1 = fixture_user(num: 1)
      user2 = fixture_user(num: 2)

      attrs1 = %{
        "capacity" => 42,
        "deadline" => "2100-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2100-04-17T14:00:00Z",
        "name" => "some name",
        "type" => 1,
        "join" => "false",
        "url" => "some url",
        "platform" => 1,
        "master_id" => user1.id
      }

      attrs2 = %{
        "capacity" => 42,
        "deadline" => "2100-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2100-04-17T14:00:00Z",
        "name" => "some name",
        "type" => 1,
        "join" => "false",
        "url" => "some url",
        "platform" => 1,
        "master_id" => user2.id
      }

      attrs3 = %{
        "capacity" => 42,
        "deadline" => "2200-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2200-04-17T14:00:00Z",
        "name" => "some name",
        "type" => 1,
        "join" => "false",
        "url" => "some url",
        "platform" => 1,
        "master_id" => user2.id
      }

      conn = post(conn, Routes.tournament_path(conn, :create), %{tournament: attrs1, file: ""})
      tournament1 = json_response(conn, 200)["data"]

      conn =
        get(conn, Routes.tournament_path(conn, :is_able_to_join), %{
          user_id: user1.id,
          tournament_id: tournament1["id"]
        })

      assert json_response(conn, 200)["result"]

      # same time as attrs1
      conn = post(conn, Routes.tournament_path(conn, :create), %{tournament: attrs2, file: ""})
      tournament2 = json_response(conn, 200)["data"]

      conn =
        get(conn, Routes.tournament_path(conn, :is_able_to_join), %{
          user_id: user1.id,
          tournament_id: tournament2["id"]
        })

      refute json_response(conn, 200)["result"]

      conn =
        get(conn, Routes.tournament_path(conn, :is_able_to_join), %{
          user_id: user2.id,
          tournament_id: tournament1["id"]
        })

      refute json_response(conn, 200)["result"]

      conn = post(conn, Routes.tournament_path(conn, :create), %{tournament: attrs3, file: ""})
      tournament3 = json_response(conn, 200)["data"]

      conn =
        get(conn, Routes.tournament_path(conn, :is_able_to_join), %{
          user_id: user1.id,
          tournament_id: tournament3["id"]
        })

      assert json_response(conn, 200)["result"]

      create_entrants(tournament3["capacity"], tournament3["id"])

      conn =
        get(conn, Routes.tournament_path(conn, :is_able_to_join), %{
          user_id: user1.id,
          tournament_id: tournament3["id"]
        })

      refute json_response(conn, 200)["result"]
    end
  end

  describe "is started?" do
    test "works", %{conn: conn} do
      user1 = fixture_user(num: 1)
      user2 = fixture_user(num: 2)

      attrs1 = %{
        "capacity" => 42,
        "deadline" => "2100-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2100-04-17T14:00:00Z",
        "name" => "some name",
        "type" => 1,
        "join" => "false",
        "url" => "some url",
        "platform" => 1,
        "master_id" => user1.id,
        "is_started" => true
      }

      conn = post(conn, Routes.tournament_path(conn, :create), %{tournament: attrs1, file: ""})
      tournament = json_response(conn, 200)["data"]
      conn = get(conn, Routes.tournament_path(conn, :is_started_at_least_one), user_id: user1.id)
      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["tournament_id"] == tournament["id"]

      conn = get(conn, Routes.tournament_path(conn, :is_started_at_least_one), user_id: user2.id)
      refute json_response(conn, 200)["result"]
      assert is_nil(json_response(conn, 200)["tournament_id"])

      %{
        "rank" => 0,
        "tournament_id" => tournament["id"],
        "user_id" => user2.id
      }
      |> Tournaments.create_entrant()

      conn = get(conn, Routes.tournament_path(conn, :is_started_at_least_one), user_id: user2.id)
      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["tournament_id"] == tournament["id"]
    end
  end

  describe "tournament topics" do
    setup [:create_tournament]

    test "works", %{conn: conn, tournament: tournament} do
      conn =
        get(conn, Routes.tournament_path(conn, :tournament_topics),
          tournament_id: tournament.id,
          user_id: tournament.master_id
        )

      json_response(conn, 200)
      |> Map.get("data")
      |> Enum.map(fn topic ->
        ["Group", "Notification", "Q&A"]
        |> Enum.member?(topic["topic_name"])
        |> (fn mem ->
              assert mem
            end).()

        assert topic["tournament_id"] == tournament.id

        if topic["topic_name"] == "Notification" do
          assert topic["authority"] == 1
        else
          assert topic["authority"] == 0
        end
      end)
      |> length()
      |> (fn len ->
            assert len == 3
          end).()
    end
  end

  describe "update tournament topic" do
    setup [:create_tournament]

    test "works", %{conn: conn, tournament: tournament} do
      tabs = [
        %{
          "chat_room_id" => nil,
          "tab_index" => 0,
          "topic_name" => "test_topic1"
        },
        %{
          "chat_room_id" => nil,
          "tab_index" => 1,
          "topic_name" => "test_topic2"
        }
      ]

      tab_name_list = Enum.map(tabs, fn tab -> tab["topic_name"] end)

      conn =
        post(conn, Routes.tournament_path(conn, :tournament_update_topics),
          tournament_id: tournament.id,
          tabs: tabs
        )

      json_response(conn, 200)
      |> Map.get("data")
      |> Enum.map(fn tab ->
        assert Enum.member?(tab_name_list, tab["topic_name"])
      end)
      |> length()
      |> (fn len ->
            assert len == 2
          end).()
    end
  end

  describe "start tournament" do
    setup [:create_tournament]

    test "start a tournament with valid data (type: 1)", %{conn: conn, tournament: tournament} do
      _entrants = create_entrants(12, tournament.id)

      conn =
        post(conn, Routes.tournament_path(conn, :start),
          tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id}
        )

      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["data"]["match_list"] |> is_list()

      assert Tournaments.get_entrants(tournament.id)
             |> Enum.map(fn x -> x.rank end)
             |> Enum.filter(fn x -> x == 8 end)
             |> length()
             |> Kernel.==(4)
    end

    test "start a tournament with valid data (type: 2)", %{conn: conn, tournament: _tournament} do
      create_attrs2 = %{
        "capacity" => 42,
        "deadline" => "2010-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2010-04-17T14:00:00Z",
        "master_id" => 42,
        "name" => "some name",
        "type" => 2,
        "join" => "true",
        "url" => "some url",
        "password" => "Password123",
        "platform" => 1
      }

      Platforms.create_basic_platforms()

      {:ok, user} =
        %{"name" => "type2name", "email" => "type2e@mail.com", "password" => "Password123"}
        |> Accounts.create_user()

      {:ok, tournament} = Tournaments.create_tournament(%{create_attrs2 | "master_id" => user.id})

      entrants = create_entrants(8, tournament.id)
      entrant_id_list = Enum.map(entrants, fn entrant -> entrant.user_id end)

      conn =
        post(conn, Routes.tournament_path(conn, :start),
          tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id}
        )

      json_response(conn, 200)
      |> Map.get("data")
      |> Map.get("match_list")
      |> List.flatten()
      |> Enum.map(fn user_id ->
        assert user_id in entrant_id_list
      end)
      |> length()
      |> (fn len ->
            assert len == length(entrants)
          end).()

      tournament.id
      |> TournamentProgress.get_match_list()
      |> List.flatten()
      |> Enum.map(fn user_id ->
        assert user_id in entrant_id_list
      end)
      |> length()
      |> (fn len ->
            assert len == length(entrants)
          end).()

      tournament.id
      |> TournamentProgress.get_match_list_with_fight_result()
      |> List.flatten()
      |> length()
      |> (fn len ->
            assert len == length(entrants)
          end).()
    end

    test "start a tournament with valid data (type: 3)", %{conn: conn, tournament: _tournament} do
      create_attrs2 = %{
        "capacity" => 42,
        "deadline" => "2010-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2010-04-17T14:00:00Z",
        "master_id" => 42,
        "name" => "some name",
        "type" => 3,
        "join" => "true",
        "url" => "some url",
        "password" => "Password123",
        "platform" => 1
      }

      Platforms.create_basic_platforms()

      {:ok, user} =
        %{"name" => "type2name", "email" => "type2e@mail.com", "password" => "Password123"}
        |> Accounts.create_user()

      {:ok, tournament} = Tournaments.create_tournament(%{create_attrs2 | "master_id" => user.id})

      entrants = create_entrants(8, tournament.id)
      entrant_id_list = Enum.map(entrants, fn entrant -> entrant.user_id end)

      conn =
        post(conn, Routes.tournament_path(conn, :start),
          tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id}
        )

      json_response(conn, 200)
      |> Map.get("data")
      |> Map.get("match_list")
      |> List.flatten()
      |> Enum.map(fn user_id ->
        assert user_id in entrant_id_list
      end)
      |> length()
      |> (fn len ->
            assert len == length(entrants)
          end).()

      tournament.id
      |> TournamentProgress.get_match_list()
      |> List.flatten()
      |> Enum.map(fn user_id ->
        assert user_id in entrant_id_list
      end)
      |> length()
      |> (fn len ->
            assert len == length(entrants)
          end).()

      tournament.id
      |> TournamentProgress.get_match_list_with_fight_result()
      |> List.flatten()
      |> length()
      |> (fn len ->
            assert len == length(entrants)
          end).()
    end

    test "does not work (type: -1)", %{conn: conn, tournament: _tournament} do
      create_attrs2 = %{
        "capacity" => 42,
        "deadline" => "2010-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2010-04-17T14:00:00Z",
        "master_id" => 42,
        "name" => "some name",
        "type" => -1,
        "join" => "true",
        "url" => "some url",
        "password" => "Password123",
        "platform" => 1
      }

      Platforms.create_basic_platforms()

      {:ok, user} =
        %{"name" => "type2name", "email" => "type2e@mail.com", "password" => "Password123"}
        |> Accounts.create_user()

      {:ok, tournament} = Tournaments.create_tournament(%{create_attrs2 | "master_id" => user.id})
      create_entrants(8, tournament.id)

      conn =
        post(conn, Routes.tournament_path(conn, :start),
          tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id}
        )

      refute json_response(conn, 200)["result"]
    end
  end

  describe "delete loser" do
    setup [:create_tournament]

    test "works", %{conn: conn, tournament: tournament} do
      entrants = create_entrants(8, tournament.id)

      conn =
        post(conn, Routes.tournament_path(conn, :start),
          tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id}
        )

      match_list = json_response(conn, 200)["data"]["match_list"]

      # TODO: redisの確認もしておきたい
      losers = [hd(entrants).user_id]

      conn =
        post(conn, Routes.tournament_path(conn, :delete_loser),
          tournament: %{tournament_id: tournament.id, loser_list: losers}
        )

      json_response(conn, 200)
      |> Map.get("updated_match_list")
      |> (fn list ->
            old_len =
              match_list
              |> List.flatten()
              |> length()

            new_len =
              list
              |> List.flatten()
              |> length()

            assert new_len == old_len - 1
          end).()

      TournamentProgress.get_single_tournament_match_logs(tournament.id, hd(losers))
      |> Enum.map(fn log ->
        assert log.loser_id == hd(losers)
        assert log.tournament_id == tournament.id
      end)
      |> length()
      |> (fn len ->
            assert len == 1
          end).()

      assert TournamentProgress.get_fight_result(hd(losers), tournament.id) == []
      assert TournamentProgress.get_match_pending_list(hd(losers), tournament.id) == []

      tournament.id
      |> TournamentProgress.get_match_list()
      |> List.flatten()
      |> Enum.any?(fn user_id ->
        user_id == hd(losers)
      end)
      |> (fn bool ->
            refute bool
          end).()

      tournament.id
      |> TournamentProgress.get_match_list_with_fight_result()
      |> List.flatten()
      |> Enum.any?(fn map ->
        if map["is_loser"] do
          map["user_id"] == hd(losers)
        else
          false
        end
      end)
      |> (fn bool ->
            assert bool
          end).()
    end

    test "works with integer data", %{conn: conn, tournament: tournament} do
      entrants = create_entrants(8, tournament.id)

      conn =
        post(conn, Routes.tournament_path(conn, :start),
          tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id}
        )

      match_list = json_response(conn, 200)["data"]["match_list"]

      # TODO: redisの確認もしておきたい
      losers = hd(entrants).user_id

      conn =
        post(conn, Routes.tournament_path(conn, :delete_loser),
          tournament: %{tournament_id: tournament.id, loser_list: losers}
        )

      json_response(conn, 200)
      |> Map.get("updated_match_list")
      |> (fn list ->
            old_len =
              match_list
              |> List.flatten()
              |> length()

            new_len =
              list
              |> List.flatten()
              |> length()

            assert new_len == old_len - 1
          end).()
    end

    test "works with binary data", %{conn: conn, tournament: tournament} do
      entrants = create_entrants(8, tournament.id)

      conn =
        post(conn, Routes.tournament_path(conn, :start),
          tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id}
        )

      match_list = json_response(conn, 200)["data"]["match_list"]

      # TODO: redisの確認もしておきたい
      losers =
        entrants
        |> hd()
        |> Map.get(:user_id)
        |> to_string()

      conn =
        post(conn, Routes.tournament_path(conn, :delete_loser),
          tournament: %{tournament_id: tournament.id, loser_list: losers}
        )

      json_response(conn, 200)
      |> Map.get("updated_match_list")
      |> (fn list ->
            old_len =
              match_list
              |> List.flatten()
              |> length()

            new_len =
              list
              |> List.flatten()
              |> length()

            assert new_len == old_len - 1
          end).()
    end
  end

  describe "find match" do
    setup [:create_tournament]

    test "works", %{conn: conn, tournament: tournament} do
      entrants = create_entrants(8, tournament.id)

      conn =
        post(conn, Routes.tournament_path(conn, :start),
          tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id}
        )

      conn =
        get(conn, Routes.tournament_path(conn, :find_match),
          tournament_id: tournament.id,
          user_id: tournament.master_id
        )

      json_response(conn, 200)
      |> Map.get("match")
      |> (fn match ->
            assert match == []
          end).()

      conn =
        get(conn, Routes.tournament_path(conn, :find_match),
          tournament_id: tournament.id,
          user_id: hd(entrants).user_id
        )

      json_response(conn, 200)
      |> Map.get("match")
      |> (fn match ->
            assert hd(entrants).user_id in match
            match
          end).()
      |> length()
      |> (fn len ->
            assert len == 2
          end).()
    end
  end

  # TODO: redisの確認もしておきたい
  describe "get match list" do
    setup [:create_tournament]

    test "works", %{conn: conn, tournament: tournament} do
      entrants = create_entrants(8, tournament.id)

      conn =
        post(conn, Routes.tournament_path(conn, :start),
          tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id}
        )

      user_id_list = Enum.map(entrants, fn entrant -> entrant.user_id end)

      conn =
        get(conn, Routes.tournament_path(conn, :get_match_list), tournament_id: tournament.id)

      assert json_response(conn, 200)["result"]

      json_response(conn, 200)
      |> Map.get("match_list")
      |> List.flatten()
      |> Enum.map(fn user_id ->
        assert user_id in user_id_list
        user_id
      end)
      |> length()
      |> (fn len ->
            assert len == length(user_id_list)
          end).()
    end
  end

  describe "start match" do
    setup [:create_tournament]

    test "works", %{conn: conn, tournament: tournament} do
      entrants = create_entrants(8, tournament.id)

      conn =
        post(conn, Routes.tournament_path(conn, :start),
          tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id}
        )

      user1_id = hd(entrants).user_id

      conn =
        post(conn, Routes.tournament_path(conn, :start_match),
          user_id: user1_id,
          tournament_id: tournament.id
        )

      assert json_response(conn, 200)["result"]

      conn =
        get(conn, Routes.tournament_path(conn, :get_opponent),
          tournament_id: tournament.id,
          user_id: user1_id
        )

      opponent1_id = json_response(conn, 200)["opponent"]["id"]

      conn =
        post(conn, Routes.tournament_path(conn, :start_match),
          user_id: opponent1_id,
          tournament_id: tournament.id
        )

      assert json_response(conn, 200)["result"]

      gotten_id_list =
        tournament.id
        |> TournamentProgress.get_match_pending_list_of_tournament()
        |> Enum.map(fn id_str ->
          String.to_integer(id_str)
        end)

      assert user1_id in gotten_id_list
      assert opponent1_id in gotten_id_list
    end
  end

  describe "get opponent" do
    setup [:create_tournament]

    test "get an opponent of a started tournament with valid data", %{
      conn: conn,
      tournament: tournament
    } do
      entrants = create_entrants(8, tournament.id)

      conn =
        post(conn, Routes.tournament_path(conn, :start),
          tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id}
        )

      conn =
        get(conn, Routes.tournament_path(conn, :get_opponent), %{
          "tournament_id" => tournament.id,
          "user_id" => hd(entrants).user_id
        })

      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["opponent"]
    end
  end

  describe "get fighting users" do
    setup [:create_tournament]

    test "get fighting users", %{conn: conn, tournament: tournament} do
      entrants = create_entrants(8, tournament.id)
      player = hd(entrants)

      conn =
        post(conn, Routes.tournament_path(conn, :start),
          tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id}
        )

      conn =
        get(conn, Routes.tournament_path(conn, :get_opponent), %{
          "tournament_id" => tournament.id,
          "user_id" => player.user_id
        })

      opponent = json_response(conn, 200)["opponent"]

      conn =
        get(conn, Routes.tournament_path(conn, :get_fighting_users), tournament_id: tournament.id)

      assert json_response(conn, 200)["data"] == []

      conn =
        post(conn, Routes.tournament_path(conn, :start_match),
          user_id: player.user_id,
          tournament_id: tournament.id
        )

      assert json_response(conn, 200)["result"]

      conn =
        get(conn, Routes.tournament_path(conn, :get_fighting_users), tournament_id: tournament.id)

      assert length(json_response(conn, 200)["data"]) == 1

      conn =
        post(conn, Routes.tournament_path(conn, :start_match),
          user_id: opponent["id"],
          tournament_id: tournament.id
        )

      assert json_response(conn, 200)["result"]

      conn =
        get(conn, Routes.tournament_path(conn, :get_fighting_users), tournament_id: tournament.id)

      assert length(json_response(conn, 200)["data"]) == 2

      conn =
        post(conn, Routes.tournament_path(conn, :claim_win),
          opponent_id: opponent["id"],
          user_id: player.user_id,
          tournament_id: tournament.id
        )

      conn =
        post(conn, Routes.tournament_path(conn, :claim_lose),
          opponent_id: player.user_id,
          user_id: opponent["id"],
          tournament_id: tournament.id
        )

      conn =
        get(conn, Routes.tournament_path(conn, :get_fighting_users), tournament_id: tournament.id)

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
        |> post(Routes.tournament_path(conn, :start),
          tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id}
        )
        |> get(Routes.tournament_path(conn, :get_opponent), %{
          "tournament_id" => tournament.id,
          "user_id" => player.user_id
        })

      opponent = json_response(conn, 200)["opponent"]

      conn =
        get(conn, Routes.tournament_path(conn, :get_waiting_users), tournament_id: tournament.id)

      json_response(conn, 200)
      |> Map.get("data")
      |> length()
      |> (fn len ->
            assert len == length(entrants)
          end).()

      conn =
        post(conn, Routes.tournament_path(conn, :start_match),
          user_id: player.user_id,
          tournament_id: tournament.id
        )

      assert json_response(conn, 200)["result"]

      conn =
        get(conn, Routes.tournament_path(conn, :get_waiting_users), tournament_id: tournament.id)

      assert length(json_response(conn, 200)["data"]) == length(entrants) - 1

      conn =
        post(conn, Routes.tournament_path(conn, :start_match),
          user_id: opponent["id"],
          tournament_id: tournament.id
        )

      assert json_response(conn, 200)["result"]

      conn =
        get(conn, Routes.tournament_path(conn, :get_waiting_users), tournament_id: tournament.id)

      assert length(json_response(conn, 200)["data"]) == length(entrants) - 2

      conn =
        post(conn, Routes.tournament_path(conn, :claim_win),
          opponent_id: opponent["id"],
          user_id: player.user_id,
          tournament_id: tournament.id
        )

      conn =
        post(conn, Routes.tournament_path(conn, :claim_lose),
          opponent_id: player.user_id,
          user_id: opponent["id"],
          tournament_id: tournament.id
        )

      conn =
        post(conn, Routes.tournament_path(conn, :delete_loser),
          tournament: %{tournament_id: tournament.id, loser_list: [opponent["id"]]}
        )

      conn =
        get(conn, Routes.tournament_path(conn, :get_waiting_users), tournament_id: tournament.id)

      assert length(json_response(conn, 200)["data"]) == length(entrants) - 1
    end
  end

  describe "check pending" do
    setup [:create_tournament]

    test "works", %{conn: conn, tournament: tournament} do
      entrants = create_entrants(8, tournament.id)

      conn =
        post(conn, Routes.tournament_path(conn, :start),
          tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id}
        )

      user1_id = hd(entrants).id

      conn =
        get(conn, Routes.tournament_path(conn, :check_pending),
          user_id: user1_id,
          tournament_id: tournament.id
        )

      refute json_response(conn, 200)["result"]

      conn =
        post(conn, Routes.tournament_path(conn, :start_match),
          user_id: user1_id,
          tournament_id: tournament.id
        )

      conn =
        get(conn, Routes.tournament_path(conn, :check_pending),
          user_id: user1_id,
          tournament_id: tournament.id
        )

      assert json_response(conn, 200)["result"]
    end
  end

  describe "has lost?" do
    setup [:create_tournament]

    test "works", %{conn: conn, tournament: tournament} do
      entrants = create_entrants(8, tournament.id)

      conn =
        post(conn, Routes.tournament_path(conn, :start),
          tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id}
        )

      user1_id = hd(entrants).user_id

      conn =
        get(conn, Routes.tournament_path(conn, :has_lost?),
          user_id: user1_id,
          tournament_id: tournament.id
        )

      refute json_response(conn, 200)["has_lost"]

      conn =
        get(conn, Routes.tournament_path(conn, :get_opponent),
          tournament_id: tournament.id,
          user_id: user1_id
        )

      opponent1_id = json_response(conn, 200)["opponent"]["id"]

      conn =
        post(conn, Routes.tournament_path(conn, :claim_win),
          opponent_id: user1_id,
          user_id: opponent1_id,
          tournament_id: tournament.id
        )

      conn =
        post(conn, Routes.tournament_path(conn, :claim_lose),
          opponent_id: opponent1_id,
          user_id: user1_id,
          tournament_id: tournament.id
        )

      conn =
        post(conn, Routes.tournament_path(conn, :delete_loser),
          tournament: %{"tournament_id" => tournament.id, "loser_list" => [user1_id]}
        )

      conn =
        get(conn, Routes.tournament_path(conn, :has_lost?),
          user_id: user1_id,
          tournament_id: tournament.id
        )

      assert json_response(conn, 200)["has_lost"]
    end
  end

  describe "state" do
    setup [:create_tournament]

    test "works", %{conn: conn, tournament: tournament} do
      entrants = create_entrants(8, tournament.id)
      user1_id = hd(entrants).user_id

      conn =
        get(conn, Routes.tournament_path(conn, :state),
          tournament_id: tournament.id,
          user_id: user1_id
        )

      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["state"] == "IsNotStarted"

      conn =
        post(conn, Routes.tournament_path(conn, :start),
          tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id}
        )

      conn =
        get(conn, Routes.tournament_path(conn, :state),
          tournament_id: tournament.id,
          user_id: user1_id
        )

      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["state"] == "IsInMatch"

      conn =
        get(conn, Routes.tournament_path(conn, :state),
          tournament_id: tournament.id,
          user_id: tournament.master_id
        )

      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["state"] == "IsManager"

      conn =
        get(conn, Routes.tournament_path(conn, :get_opponent),
          tournament_id: tournament.id,
          user_id: user1_id
        )

      opponent1_id = json_response(conn, 200)["opponent"]["id"]

      conn =
        post(conn, Routes.tournament_path(conn, :start_match),
          user_id: user1_id,
          tournament_id: tournament.id
        )

      conn =
        get(conn, Routes.tournament_path(conn, :state),
          tournament_id: tournament.id,
          user_id: user1_id
        )

      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["state"] == "IsWaitingForStart"

      conn =
        post(conn, Routes.tournament_path(conn, :start_match),
          user_id: opponent1_id,
          tournament_id: tournament.id
        )

      conn =
        get(conn, Routes.tournament_path(conn, :state),
          tournament_id: tournament.id,
          user_id: user1_id
        )

      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["state"] == "IsPending"

      conn =
        post(conn, Routes.tournament_path(conn, :claim_win),
          opponent_id: opponent1_id,
          user_id: user1_id,
          tournament_id: tournament.id
        )

      conn =
        post(conn, Routes.tournament_path(conn, :claim_lose),
          opponent_id: user1_id,
          user_id: opponent1_id,
          tournament_id: tournament.id
        )

      conn =
        post(conn, Routes.tournament_path(conn, :delete_loser),
          tournament: %{"tournament_id" => tournament.id, "loser_list" => [opponent1_id]}
        )

      conn =
        get(conn, Routes.tournament_path(conn, :state),
          tournament_id: tournament.id,
          user_id: user1_id
        )

      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["state"] == "IsAlone"
    end
  end

  describe "is user win" do
    setup [:create_tournament]

    test "works", %{conn: conn, tournament: tournament} do
      entrants = create_entrants(8, tournament.id)

      conn =
        post(conn, Routes.tournament_path(conn, :start),
          tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id}
        )

      user1_id = hd(entrants).user_id

      conn =
        get(conn, Routes.tournament_path(conn, :get_opponent),
          tournament_id: tournament.id,
          user_id: user1_id
        )

      opponent1_id = json_response(conn, 200)["opponent"]["id"]

      conn =
        post(conn, Routes.tournament_path(conn, :claim_win),
          opponent_id: opponent1_id,
          user_id: user1_id,
          tournament_id: tournament.id
        )

      conn =
        get(conn, Routes.tournament_path(conn, :is_user_win),
          user_id: user1_id,
          tournament_id: tournament.id
        )

      assert json_response(conn, 200)["is_win"]

      conn =
        get(conn, Routes.tournament_path(conn, :is_user_win),
          user_id: opponent1_id,
          tournament_id: tournament.id
        )

      refute json_response(conn, 200)["is_win"]
    end
  end

  describe "score" do
    test "works", %{conn: conn} do
      create_attrs2 = %{
        "capacity" => 42,
        "deadline" => "2010-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2010-04-17T14:00:00Z",
        "master_id" => 42,
        "name" => "some name",
        "type" => 2,
        "join" => "true",
        "url" => "some url",
        "password" => "Password123",
        "platform" => 1
      }

      Platforms.create_basic_platforms()

      {:ok, user} =
        %{"name" => "type2name", "email" => "type2e@mail.com", "password" => "Password123"}
        |> Accounts.create_user()

      {:ok, tournament} = Tournaments.create_tournament(%{create_attrs2 | "master_id" => user.id})

      [entrant1, _, _, _] = create_entrants(4, tournament.id)

      conn =
        post(conn, Routes.tournament_path(conn, :start),
          tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id}
        )

      conn =
        get(conn, Routes.tournament_path(conn, :get_opponent), %{
          "tournament_id" => tournament.id,
          "user_id" => entrant1.user_id
        })

      opponent = json_response(conn, 200)["opponent"]

      conn =
        post(conn, Routes.tournament_path(conn, :start_match),
          user_id: entrant1.user_id,
          tournament_id: tournament.id
        )

      conn =
        post(conn, Routes.tournament_path(conn, :start_match),
          user_id: opponent["id"],
          tournament_id: tournament.id
        )

      my_score = 13
      match_index = 1

      conn =
        post(conn, Routes.tournament_path(conn, :claim_score),
          tournament_id: tournament.id,
          user_id: entrant1.user_id,
          opponent_id: opponent["id"],
          score: my_score,
          match_index: match_index
        )

      conn =
        get(conn, Routes.tournament_path(conn, :score),
          tournament_id: tournament.id,
          user_id: entrant1.user_id
        )

      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["score"] == 13

      conn =
        get(conn, Routes.tournament_path(conn, :score),
          tournament_id: tournament.id,
          user_id: opponent["id"]
        )

      refute json_response(conn, 200)["result"]

      json_response(conn, 200)
      |> Map.get("score")
      |> is_nil()
      |> (fn isnil ->
            assert isnil
          end).()
    end
  end

  describe "force to defeat" do
    setup [:create_tournament]

    test "works with size 4 tournament", %{conn: conn, tournament: tournament} do
      entrants = create_entrants(4, tournament.id)
      entrant1 = hd(entrants)

      conn =
        post(conn, Routes.tournament_path(conn, :start),
          tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id}
        )

      conn =
        get(conn, Routes.tournament_path(conn, :chunk_bracket_data_for_best_of_format), %{
          "tournament_id" => tournament.id
        })

      conn =
        get(conn, Routes.tournament_path(conn, :get_opponent), %{
          "tournament_id" => tournament.id,
          "user_id" => entrant1.user_id
        })

      opponent = json_response(conn, 200)["opponent"]

      conn =
        post(conn, Routes.tournament_path(conn, :force_to_defeat),
          tournament_id: tournament.id,
          target_user_id: entrant1.user_id
        )

      conn =
        get(conn, Routes.tournament_path(conn, :chunk_bracket_data_for_best_of_format), %{
          "tournament_id" => tournament.id
        })

      assert json_response(conn, 200)["result"]

      json_response(conn, 200)
      |> Map.get("data")
      |> Enum.map(fn bracket ->
        if bracket["user_id"] == entrant1.user_id do
          assert bracket["is_loser"]
          assert bracket["game_scores"] == [-1]
        else
          refute bracket["is_loser"]
        end
      end)
      |> length()
      |> (fn len ->
            assert len == length(entrants)
          end).()

      conn =
        post(conn, Routes.tournament_path(conn, :force_to_defeat),
          tournament_id: tournament.id,
          target_user_id: opponent["id"]
        )

      conn =
        get(conn, Routes.tournament_path(conn, :chunk_bracket_data_for_best_of_format), %{
          "tournament_id" => tournament.id
        })

      json_response(conn, 200)
      |> Map.get("data")
      |> Enum.map(fn bracket ->
        if bracket["user_id"] == entrant1.user_id || bracket["user_id"] == opponent["id"] do
          assert bracket["is_loser"]
        else
          refute bracket["is_loser"]
        end
      end)
      |> length()
      |> (fn len ->
            assert len == length(entrants)
          end).()

      conn = get(conn, Routes.tournament_path(conn, :get_entrants), tournament_id: tournament.id)

      json_response(conn, 200)
      |> Map.get("data")
      |> Enum.each(fn entrant ->
        cond do
          entrant["user_id"] == opponent["id"] ->
            assert entrant["rank"] == 2

          entrant["user_id"] == entrant1.user_id ->
            assert entrant["rank"] == 4

          true ->
            assert entrant["rank"] == 2
        end
      end)

      match_list = TournamentProgress.get_match_list(tournament.id)
      loser = hd(match_list)

      conn =
        post(conn, Routes.tournament_path(conn, :force_to_defeat),
          tournament_id: tournament.id,
          target_user_id: loser
        )

      conn =
        get(conn, Routes.tournament_path(conn, :chunk_bracket_data_for_best_of_format), %{
          "tournament_id" => tournament.id
        })

      json_response(conn, 200)
      |> Map.get("data")
      |> Enum.map(fn bracket ->
        if bracket["user_id"] == entrant1.user_id || bracket["user_id"] == opponent["id"] ||
             bracket["user_id"] == loser do
          assert bracket["is_loser"]
        else
          refute bracket["is_loser"]
        end
      end)
      |> length()
      |> (fn len ->
            assert len == length(entrants)
          end).()

      conn = get(conn, Routes.tournament_path(conn, :show), tournament_id: tournament.id)
      assert json_response(conn, 200)["is_log"]

      assert TournamentProgress.get_match_list_with_fight_result(tournament.id) == []
    end
  end

  describe "publish url" do
    test "works", %{conn: conn} do
      conn = post(conn, Routes.tournament_path(conn, :publish_url))
      assert json_response(conn, 200)["result"]

      json_response(conn, 200)
      |> Map.get("url")
      |> is_binary()
      |> (fn bool ->
            assert bool
          end).()
    end
  end

  describe "get match members" do
    setup [:create_tournament]

    test "works", %{conn: conn, tournament: tournament} do
      _entrants = create_entrants(8, tournament.id)

      conn =
        post(conn, Routes.tournament_path(conn, :start),
          tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id}
        )

      conn =
        get(conn, Routes.tournament_path(conn, :get_match_members), tournament_id: tournament.id)

      response = json_response(conn, 200)

      response
      |> Map.get("data")
      |> Map.get("assistants")
      |> length()
      |> (fn len ->
            assert len == 0
          end).()

      response
      |> Map.get("data")
      |> Map.get("entrants")
      |> length()
      |> (fn len ->
            assert len == 8
          end).()

      response
      |> Map.get("data")
      |> Map.get("master")
      |> Map.get("data")
      |> (fn user ->
            assert user["id"] == tournament.master_id
          end).()
    end
  end

  # TODO: redisの確認を入れたい
  describe "test duplicate claim members" do
    setup [:create_tournament]

    test "get duplicate claim members", %{conn: conn, tournament: tournament} do
      entrants = create_entrants(17, tournament.id)
      player = hd(entrants)

      conn =
        post(conn, Routes.tournament_path(conn, :start),
          tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id}
        )

      conn =
        get(conn, Routes.tournament_path(conn, :get_opponent), %{
          "tournament_id" => tournament.id,
          "user_id" => player.user_id
        })

      response = json_response(conn, 200)

      cond do
        !is_nil(response["opponent"]) -> true
        is_nil(response["opponent"]) and !is_nil(response["wait"]) -> false
        true -> assert false, "it must not be true"
      end
      |> if do
        opponent = response["opponent"]

        conn =
          post(conn, Routes.tournament_path(conn, :start_match),
            user_id: player.user_id,
            tournament_id: tournament.id
          )

        conn =
          post(conn, Routes.tournament_path(conn, :start_match),
            user_id: opponent["id"],
            tournament_id: tournament.id
          )

        conn =
          post(conn, Routes.tournament_path(conn, :claim_win),
            opponent_id: opponent["id"],
            user_id: player.user_id,
            tournament_id: tournament.id
          )

        conn =
          post(conn, Routes.tournament_path(conn, :claim_win),
            opponent_id: player.user_id,
            user_id: opponent["id"],
            tournament_id: tournament.id
          )

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
        |> get(Routes.tournament_path(conn, :get_duplicate_claim_members),
          tournament_id: tournament.id
        )
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

  describe "get game masters" do
    setup [:create_tournament]

    test "get game masters", %{conn: conn, tournament: tournament} do
      conn =
        get(conn, Routes.tournament_path(conn, :get_game_masters), tournament_id: tournament.id)

      json_response(conn, 200)
      |> Map.get("data")
      |> Enum.map(fn user ->
        assert user["id"] == tournament.master_id
      end)
      |> length()
      |> (fn len ->
            assert len == 1
          end).()
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

  describe "finish" do
    setup [:create_tournament]

    test "check status of redis and logs", %{conn: conn} do
      user = fixture_user(num: 1)
      attrs = Map.put(@create_attrs, "master_id", user.id)
      conn = post(conn, Routes.tournament_path(conn, :create), %{tournament: attrs, file: ""})
      tournament = json_response(conn, 200)["data"]

      create_entrants(1, tournament["id"])

      Map.new()
      |> Map.put("rank", 0)
      |> Map.put("tournament_id", tournament["id"])
      |> Map.put("user_id", tournament["master_id"])
      |> Tournaments.create_entrant()

      user1_id = tournament["master_id"]

      conn =
        post(conn, Routes.tournament_path(conn, :start),
          tournament: %{
            "master_id" => tournament["master_id"],
            "tournament_id" => tournament["id"]
          }
        )

      conn =
        get(conn, Routes.tournament_path(conn, :get_opponent),
          tournament_id: tournament["id"],
          user_id: user1_id
        )

      opponent1_id = json_response(conn, 200)["opponent"]["id"]

      conn =
        post(conn, Routes.tournament_path(conn, :start_match),
          user_id: user1_id,
          tournament_id: tournament["id"]
        )

      conn =
        post(conn, Routes.tournament_path(conn, :start_match),
          user_id: opponent1_id,
          tournament_id: tournament["id"]
        )

      conn =
        post(conn, Routes.tournament_path(conn, :claim_lose),
          user_id: user1_id,
          opponent_id: opponent1_id,
          tournament_id: tournament["id"]
        )

      conn =
        post(conn, Routes.tournament_path(conn, :claim_win),
          user_id: opponent1_id,
          opponent_id: user1_id,
          tournament_id: tournament["id"]
        )

      conn =
        post(conn, Routes.tournament_path(conn, :delete_loser),
          tournament: %{tournament_id: tournament["id"], loser_list: [user1_id]}
        )

      conn =
        get(conn, Routes.tournament_path(conn, :tournament_topics),
          tournament_id: tournament["id"],
          user_id: tournament["master_id"]
        )

      assert json_response(conn, 200)["result"]

      json_response(conn, 200)
      |> Map.get("data")
      |> Enum.map(fn topic_log ->
        assert topic_log["tournament_id"] == tournament["id"]
      end)
      |> length()
      |> (fn len ->
            assert len == 3
          end).()

      conn =
        post(conn, Routes.tournament_path(conn, :finish),
          tournament_id: tournament["id"],
          user_id: opponent1_id
        )

      assert json_response(conn, 200)["result"]

      conn = get(conn, Routes.tournament_path(conn, :show), tournament_id: tournament["id"])

      json_response(conn, 200)
      |> (fn t ->
            assert t["is_log"]
            assert t["result"]
            t
          end).()
      |> Map.get("data")
      |> (fn t ->
            assert t["tournament_id"] == tournament["id"]
            assert t["capacity"] == tournament["capacity"]
            assert t["description"] == tournament["description"]
            assert t["game_id"] == tournament["game_id"]
            assert t["game_name"] == tournament["game_name"]
            assert t["winner_id"] == opponent1_id
            assert t["master_id"] == tournament["master_id"]
            assert t["name"] == tournament["name"]
            assert t["url"] == tournament["url"]
            assert t["type"] == tournament["type"]
          end).()

      conn =
        get(conn, Routes.tournament_path(conn, :tournament_topics),
          tournament_id: tournament["id"],
          user_id: tournament["master_id"]
        )

      assert json_response(conn, 200)["result"]

      json_response(conn, 200)
      |> Map.get("data")
      |> Enum.map(fn topic_log ->
        assert topic_log["tournament_id"] == tournament["id"]
      end)
      |> length()
      |> (fn len ->
            assert len == 3
          end).()

      TournamentProgress.get_match_list(tournament["id"])
      |> (fn list ->
            assert list == []
          end).()

      TournamentProgress.get_match_list_with_fight_result(tournament["id"])
      |> (fn list ->
            assert list == []
          end).()

      TournamentProgress.get_match_list_with_fight_result_including_log(tournament["id"])
      |> (fn list ->
            list
            |> length()
            |> Kernel.==(2)
            |> assert()
          end).()

      TournamentProgress.get_match_pending_list_of_tournament(tournament["id"])
      |> (fn list ->
            assert list == []
          end).()
    end
  end

  describe "brackets with fight result" do
    setup [:create_tournament]

    test "works", %{conn: conn, tournament: tournament} do
      entrants = create_entrants(8, tournament.id)

      conn =
        post(conn, Routes.tournament_path(conn, :start),
          tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id}
        )

      user_id_list = Enum.map(entrants, fn entrant -> entrant.user_id end)

      conn =
        get(conn, Routes.tournament_path(conn, :brackets_with_fight_result),
          tournament_id: tournament.id
        )

      assert json_response(conn, 200)["count"] == length(entrants)

      json_response(conn, 200)
      |> Map.get("data")
      |> List.flatten()
      |> Enum.map(fn bracket ->
        refute bracket["is_loser"]
        assert bracket["user_id"] in user_id_list
      end)
      |> length()
      |> (fn len ->
            assert len == 8
          end).()

      user1_id = hd(entrants).user_id

      conn =
        get(conn, Routes.tournament_path(conn, :get_opponent),
          tournament_id: tournament.id,
          user_id: user1_id
        )

      opponent1_id = json_response(conn, 200)["opponent"]["id"]

      conn =
        post(conn, Routes.tournament_path(conn, :claim_win),
          opponent_id: opponent1_id,
          user_id: user1_id,
          tournament_id: tournament.id
        )

      conn =
        post(conn, Routes.tournament_path(conn, :claim_lose),
          opponent_id: user1_id,
          user_id: opponent1_id,
          tournament_id: tournament.id
        )

      conn =
        post(conn, Routes.tournament_path(conn, :delete_loser),
          tournament: %{"tournament_id" => tournament.id, "loser_list" => [opponent1_id]}
        )

      conn =
        get(conn, Routes.tournament_path(conn, :brackets_with_fight_result),
          tournament_id: tournament.id
        )

      assert json_response(conn, 200)["count"] == length(entrants)

      json_response(conn, 200)
      |> Map.get("data")
      |> List.flatten()
      |> Enum.map(fn bracket ->
        if bracket["user_id"] == opponent1_id do
          assert bracket["is_loser"]
        else
          refute bracket["is_loser"]
        end

        assert bracket["user_id"] in user_id_list
      end)
      |> length()
      |> (fn len ->
            assert len == 8
          end).()
    end
  end

  describe "bracket data for best format" do
    test "works", %{conn: conn} do
      create_attrs2 = %{
        "capacity" => 42,
        "deadline" => "2010-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2010-04-17T14:00:00Z",
        "master_id" => 42,
        "name" => "some name",
        "type" => 2,
        "join" => "true",
        "url" => "some url",
        "password" => "Password123",
        "platform" => 1
      }

      Platforms.create_basic_platforms()

      {:ok, user} =
        %{"name" => "type2name", "email" => "type2e@mail.com", "password" => "Password123"}
        |> Accounts.create_user()

      {:ok, tournament} = Tournaments.create_tournament(%{create_attrs2 | "master_id" => user.id})

      [entrant1, _, _, _] = create_entrants(4, tournament.id)

      conn =
        post(conn, Routes.tournament_path(conn, :start),
          tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id}
        )

      conn =
        get(conn, Routes.tournament_path(conn, :chunk_bracket_data_for_best_of_format), %{
          "tournament_id" => tournament.id
        })

      assert json_response(conn, 200)["result"]

      json_response(conn, 200)
      |> Map.get("data")
      |> Enum.map(fn bracket ->
        refute bracket["is_loser"]
        assert bracket["game_scores"] == []
        assert bracket["win_count"] == 0
      end)
      |> length()
      |> (fn len ->
            assert len == 4
          end).()

      conn =
        get(conn, Routes.tournament_path(conn, :get_opponent), %{
          "tournament_id" => tournament.id,
          "user_id" => entrant1.user_id
        })

      opponent = json_response(conn, 200)["opponent"]

      conn =
        post(conn, Routes.tournament_path(conn, :start_match),
          user_id: entrant1.user_id,
          tournament_id: tournament.id
        )

      conn =
        post(conn, Routes.tournament_path(conn, :start_match),
          user_id: opponent["id"],
          tournament_id: tournament.id
        )

      my_score = 13
      opponent_score = 4
      match_index = 1

      conn =
        post(conn, Routes.tournament_path(conn, :claim_score),
          tournament_id: tournament.id,
          user_id: entrant1.user_id,
          opponent_id: opponent["id"],
          score: my_score,
          match_index: match_index
        )

      conn =
        post(conn, Routes.tournament_path(conn, :claim_score),
          tournament_id: tournament.id,
          user_id: opponent["id"],
          opponent_id: entrant1.user_id,
          score: opponent_score,
          match_index: match_index
        )

      conn =
        get(conn, Routes.tournament_path(conn, :chunk_bracket_data_for_best_of_format), %{
          "tournament_id" => tournament.id
        })

      assert json_response(conn, 200)["result"]

      json_response(conn, 200)
      |> Map.get("data")
      |> Enum.map(fn bracket ->
        cond do
          bracket["user_id"] == entrant1.user_id ->
            assert bracket["game_scores"] == [my_score]
            refute bracket["is_loser"]
            assert bracket["win_count"] == 1

          bracket["user_id"] == opponent["id"] ->
            assert bracket["game_scores"] == [opponent_score]
            assert bracket["is_loser"]
            assert bracket["win_count"] == 0

          true ->
            assert bracket["game_scores"] == []
            refute bracket["is_loser"]
            assert bracket["win_count"] == 0
        end
      end)
      |> length()
      |> (fn len ->
            assert len == 4
          end).()
    end
  end

  describe "chunk bracket data for best of format" do
    test "just works", %{conn: conn} do
      create_attrs2 = %{
        "capacity" => 42,
        "deadline" => "2010-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2010-04-17T14:00:00Z",
        "master_id" => 42,
        "name" => "some name",
        "type" => 2,
        "join" => "true",
        "url" => "some url",
        "password" => "Password123",
        "platform" => 1
      }

      Platforms.create_basic_platforms()

      {:ok, user} =
        %{"name" => "type2name", "email" => "type2e@mail.com", "password" => "Password123"}
        |> Accounts.create_user()

      {:ok, tournament} = Tournaments.create_tournament(%{create_attrs2 | "master_id" => user.id})

      [_, _, _] = create_entrants(3, tournament.id)

      conn =
        post(conn, Routes.tournament_path(conn, :start),
          tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id}
        )

      conn =
        get(conn, Routes.tournament_path(conn, :chunk_bracket_data_for_best_of_format), %{
          "tournament_id" => tournament.id
        })

      assert json_response(conn, 200)["result"]

      json_response(conn, 200)
      |> Map.get("data")
      |> (fn list ->
            assert is_list(list)
            assert length(list) == 4
          end).()
    end
  end

  describe "claim score" do
    test "claim_score/2 works", %{conn: conn} do
      create_attrs2 = %{
        "capacity" => 42,
        "deadline" => "2010-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2010-04-17T14:00:00Z",
        "master_id" => 42,
        "name" => "some name",
        "type" => 2,
        "join" => "true",
        "url" => "some url",
        "password" => "Password123",
        "platform" => 1
      }

      Platforms.create_basic_platforms()

      {:ok, user} =
        %{"name" => "type2name", "email" => "type2e@mail.com", "password" => "Password123"}
        |> Accounts.create_user()

      {:ok, tournament} = Tournaments.create_tournament(%{create_attrs2 | "master_id" => user.id})

      [entrant1, _, _, _] = create_entrants(4, tournament.id)

      conn =
        post(conn, Routes.tournament_path(conn, :start),
          tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id}
        )

      conn =
        get(conn, Routes.tournament_path(conn, :get_opponent), %{
          "tournament_id" => tournament.id,
          "user_id" => entrant1.user_id
        })

      entrant1.user_id
      |> TournamentProgress.get_match_pending_list(tournament.id)
      |> (fn list ->
            assert list == []
          end).()

      opponent = json_response(conn, 200)["opponent"]

      conn =
        post(conn, Routes.tournament_path(conn, :start_match),
          user_id: entrant1.user_id,
          tournament_id: tournament.id
        )

      conn =
        post(conn, Routes.tournament_path(conn, :start_match),
          user_id: opponent["id"],
          tournament_id: tournament.id
        )

      entrant1.user_id
      |> TournamentProgress.get_match_pending_list(tournament.id)
      |> (fn list ->
            assert list == [{{entrant1.user_id, tournament.id}}]
          end).()

      my_score = 13
      opponent_score = 4
      match_index = 1

      conn =
        post(conn, Routes.tournament_path(conn, :claim_score),
          tournament_id: tournament.id,
          user_id: entrant1.user_id,
          opponent_id: opponent["id"],
          score: my_score,
          match_index: match_index
        )

      json_response(conn, 200)
      |> (fn data ->
            assert data["validated"]
            refute data["completed"]
          end).()

      conn =
        get(conn, Routes.tournament_path(conn, :score),
          tournament_id: tournament.id,
          user_id: entrant1.user_id
        )

      assert json_response(conn, 200)["score"] == my_score

      my_new_score = 7

      conn =
        post(conn, Routes.tournament_path(conn, :claim_score),
          tournament_id: tournament.id,
          user_id: entrant1.user_id,
          opponent_id: opponent["id"],
          score: my_new_score,
          match_index: match_index
        )

      json_response(conn, 200)
      |> (fn data ->
            assert data["validated"]
            refute data["completed"]
          end).()

      conn =
        get(conn, Routes.tournament_path(conn, :score),
          tournament_id: tournament.id,
          user_id: entrant1.user_id
        )

      assert json_response(conn, 200)["score"] == my_new_score

      conn =
        post(conn, Routes.tournament_path(conn, :claim_score),
          tournament_id: tournament.id,
          user_id: opponent["id"],
          opponent_id: entrant1.user_id,
          score: opponent_score,
          match_index: match_index
        )

      json_response(conn, 200)
      |> (fn data ->
            assert data["validated"]
            assert data["completed"]
          end).()

      match_list =
        tournament.id
        |> TournamentProgress.get_match_list()

      match_list_with_fight_result =
        tournament.id
        |> TournamentProgress.get_match_list_with_fight_result()

      conn =
        get(conn, Routes.tournament_path(conn, :score),
          tournament_id: tournament.id,
          user_id: entrant1.user_id
        )

      refute json_response(conn, 200)["result"]
      assert is_nil(json_response(conn, 200)["score"])

      conn =
        get(conn, Routes.tournament_path(conn, :score),
          tournament_id: tournament.id,
          user_id: opponent["id"]
        )

      refute json_response(conn, 200)["result"]
      assert is_nil(json_response(conn, 200)["score"])

      match_list
      |> List.flatten()
      |> length()
      |> (fn len ->
            assert len == 3
          end).()

      match_list_with_fight_result
      |> List.flatten()
      |> Enum.map(fn bracket ->
        if bracket["user_id"] == opponent["id"] do
          assert bracket["is_loser"]
        else
          refute bracket["is_loser"]
        end
      end)
      |> length()
      |> (fn len ->
            assert len == 4
          end).()
    end

    test "claim_score/2 and finish", %{conn: conn} do
      create_attrs2 = %{
        "capacity" => 42,
        "deadline" => "2010-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2010-04-17T14:00:00Z",
        "master_id" => 42,
        "name" => "some name",
        "type" => 2,
        "join" => "true",
        "url" => "some url",
        "password" => "Password123",
        "platform" => 1
      }

      Platforms.create_basic_platforms()

      {:ok, user} =
        %{"name" => "type2name", "email" => "type2e@mail.com", "password" => "Password123"}
        |> Accounts.create_user()

      {:ok, tournament} = Tournaments.create_tournament(%{create_attrs2 | "master_id" => user.id})

      [entrant1, entrant2] = create_entrants(2, tournament.id)

      conn =
        post(conn, Routes.tournament_path(conn, :start),
          tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id}
        )

      entrant1.user_id
      |> TournamentProgress.get_match_pending_list(tournament.id)
      |> (fn list ->
            assert list == []
          end).()

      conn =
        post(conn, Routes.tournament_path(conn, :start_match),
          user_id: entrant1.user_id,
          tournament_id: tournament.id
        )

      conn =
        post(conn, Routes.tournament_path(conn, :start_match),
          user_id: entrant2.user_id,
          tournament_id: tournament.id
        )

      entrant1.user_id
      |> TournamentProgress.get_match_pending_list(tournament.id)
      |> (fn list ->
            assert list == [{{entrant1.user_id, tournament.id}}]
          end).()

      my_score = 13
      opponent_score = 4
      match_index = 1

      conn =
        post(conn, Routes.tournament_path(conn, :claim_score),
          tournament_id: tournament.id,
          user_id: entrant1.user_id,
          opponent_id: entrant2.user_id,
          score: my_score,
          match_index: match_index
        )

      json_response(conn, 200)
      |> (fn data ->
            assert data["validated"]
            refute data["completed"]
          end).()

      conn =
        post(conn, Routes.tournament_path(conn, :claim_score),
          tournament_id: tournament.id,
          user_id: entrant2.user_id,
          opponent_id: entrant1.user_id,
          score: opponent_score,
          match_index: match_index
        )

      json_response(conn, 200)
      |> (fn data ->
            assert data["validated"]
            assert data["completed"]
          end).()

      conn =
        get(conn, Routes.tournament_path(conn, :chunk_bracket_data_for_best_of_format), %{
          "tournament_id" => tournament.id
        })

      assert json_response(conn, 200)["result"]

      json_response(conn, 200)
      |> Map.get("data")
      |> Enum.map(fn bracket ->
        if bracket["user_id"] == entrant1.user_id do
          refute bracket["is_loser"]
        else
          assert bracket["is_loser"]
        end
      end)

      conn = get(conn, Routes.tournament_path(conn, :show), tournament_id: tournament.id)

      json_response(conn, 200)
      |> (fn t ->
            assert t["is_log"]
            assert t["result"]
            t
          end).()
      |> Map.get("data")
      |> (fn t ->
            assert t["tournament_id"] == tournament.id
            assert t["capacity"] == tournament.capacity
            assert t["description"] == tournament.description
            assert t["game_id"] == tournament.game_id
            assert t["game_name"] == tournament.game_name
            assert t["winner_id"] == entrant1.user_id
            assert t["master_id"] == tournament.master_id
            assert t["name"] == tournament.name
            assert t["url"] == tournament.url
            assert t["type"] == tournament.type
          end).()
    end
  end

  describe "verify password" do
    setup [:create_tournament]

    test "works", %{conn: conn, tournament: tournament} do
      conn =
        get(conn, Routes.tournament_path(conn, :verify_password), %{
          tournament_id: tournament.id,
          password: "Password123"
        })

      assert json_response(conn, 200)["result"]

      conn =
        get(conn, Routes.tournament_path(conn, :verify_password), %{
          tournament_id: tournament.id,
          password: "wrongPassword123"
        })

      refute json_response(conn, 200)["result"]
    end
  end

  # defp setup_team(n) do
  #   tournament = fixture_tournament([is_started: false, is_team: true])
  #   users = 1..n
  #     |> Enum.to_list()
  #     |> Enum.map(fn n ->
  #       fixture_user(num: n)
  #     end)
  #     |> Enum.map(fn user ->
  #       user.id
  #     end)

  #   [leader | members] = users
  #   size = n

  #   tournament.id
  #   |> Tournaments.create_team(size, leader, members)
  #   |> (fn {:ok, team} ->
  #     assert team.tournament_id == tournament.id
  #     assert team.size == size
  #   end).()

  #   {tournament, users}
  # end

  # describe "get_confirmed_teams" do
  #   test "works", %{conn: conn} do
  #     {tournament, users} = setup_team(5)
  #     [leader | members] = users

  #     conn = get(conn, Routes.tournament_path(conn, :get_confirmed_teams), tournament_id: tournament.id)
  #     json_response(conn, 200)
  #     |> Map.get("data")
  #     |> length()
  #     |> Kernel.==(0)
  #     |> assert()

  #     team = tournament.id
  #       |> Tournaments.get_teams_by_tournament_id()
  #       |> hd()

  #     team.id
  #     |> Tournaments.get_team_members_by_team_id()
  #     |> Enum.each(fn member ->
  #       Tournaments.create_team_invitation(member.id, leader, "test")
  #     end)

  #     users
  #     |> Enum.map(fn user_id ->
  #       user_id
  #       |> Tournaments.get_team_invitations_by_user_id()
  #       |> hd()
  #       |> Map.get(:id)
  #       |> Tournaments.confirm_team_invitation()
  #       |> elem(1)
  #     end)

  #     conn = get(conn, Routes.tournament_path(conn, :get_confirmed_teams), tournament_id: tournament.id)
  #     json_response(conn, 200)
  #     |> Map.get("data")
  #     |> length()
  #     |> Kernel.==(1)
  #     |> assert()
  #   end
  # end

  defp create_tournament(_) do
    tournament = fixture_tournament()
    %{tournament: tournament}
  end

  # 複数の参加者作成用関数
  defp create_entrants(num, tournament_id) do
    1..num
    |> Enum.to_list()
    |> Enum.map(fn x ->
      {:ok, user} =
        %{
          "name" => "name#{x}entrant",
          "email" => "e#{x}entrant@mail.com",
          "password" => "Password123"
        }
        |> Accounts.create_user()

      {:ok, entrant} =
        %{@entrant_create_attrs | "tournament_id" => tournament_id, "user_id" => user.id}
        |> Tournaments.create_entrant()

      entrant
    end)
  end
end

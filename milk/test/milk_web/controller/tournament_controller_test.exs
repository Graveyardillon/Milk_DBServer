defmodule MilkWeb.TournamentControllerTest do
  @moduledoc """
  Tournament Controllerに関するテスト
  """
  use MilkWeb.ConnCase
  use Common.Fixtures

  import Ecto.Query, warn: false
  import Common.{
    Sperm,
    Xor
  }

  alias Common.Tools

  alias Milk.{
    Accounts,
    Notif,
    Platforms,
    Relations,
    Repo,
    Tournaments
  }

  alias Milk.Accounts.ActionHistory
  alias Milk.Tournaments.Progress

  require Logger

  @entrant_create_attrs %{
    "rank" => 42,
    "user_id" => -1,
    "tournament_id" => -1
  }

  # @create_attrs %{
  #   "capacity" => 42,
  #   "deadline" => "2010-04-17T14:00:00Z",
  #   "description" => "some description",
  #   "event_date" => "2010-04-17T14:00:00Z",
  #   "master_id" => 42,
  #   "name" => "some name",
  #   "game_name" => "gm nm",
  #   "type" => 1,
  #   "join" => "true",
  #   "url" => "some url",
  #   "password" => "Password123",
  #   "platform" => 1
  # }
  @create_attrs %{
    "capacity" => 42,
    "deadline" => nil,
    "description" => "some description",
    "event_date" => nil,
    "master_id" => 42,
    "name" => "some name",
    "game_name" => "gm nm",
    "url" => "some url",
    "password" => "Password123",
    "platform" => 1,
    "rule" => "basic"
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
      Map.new()
      |> Map.put("name", to_string(n) <> "name")
      |> Map.put("email", to_string(n) <> "@email.com")
      |> Map.put("password", "Password123")
      |> Accounts.create_user()
      ~> {:ok, user}

      @create_attrs
      |> Map.put("master_id", user.id)
      |> Tournaments.create_tournament()
      ~> {:ok, tournament}

      tournament
    end)
  end

  def fixture_tournament_incoming() do
    user = fixture_user(num: 0)

    {:ok, tournament} = Tournaments.create_tournament(%{@create_incoming_attrs | "master_id" => user.id})

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

      conn = get(conn, Routes.tournament_path(conn, :get_planned_tournaments_by_master_id), user_id: tournament.master_id)

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
      conn = get(conn, Routes.tournament_path(conn, :get_tournament_by_url), %{url: tournament.url})

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
      |> then(fn tournament ->
        assert tournament["capacity"] == @create_attrs["capacity"]
        assert tournament["description"] == @create_attrs["description"]
        assert tournament["game_name"] == @create_attrs["game_name"]
        assert tournament["has_password"]
        assert tournament["master_id"] == user.id
        assert tournament["name"] == @create_attrs["name"]
        assert tournament["platform"] == @create_attrs["platform"]
        assert tournament["url"] == @create_attrs["url"]

        tournament["entrants"]
        |> Enum.map(fn user ->
          assert user["id"] == tournament["master_id"]
        end)
        |> Enum.empty?()
        |> assert()
      end)

      ActionHistory
      |> where([ah], ah.user_id == ^tournament["master_id"])
      |> Repo.all()
      |> Enum.map(fn action_history ->
        assert action_history.game_name == tournament["game_name"]
        assert action_history.user_id == tournament["master_id"]
        assert action_history.gain == 7
      end)
      |> length()
      |> then(fn len ->
        assert len == 1
      end)
    end

    test "renders error when date information is nil", %{conn: conn} do
      user = fixture_user()

      attrs = %{
        "capacity" => 4,
        "deadline" => nil,
        "description" => "some description",
        "event_date" => nil,
        "master_id" => user.id,
        "name" => "some name",
        "type" => 1,
        "join" => false,
        "url" => "some url",
        "platform" => 1
      }

      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: "")

      assert json_response(conn, 200)["result"]
    end

    test "renders error when date information is empty string", %{conn: conn} do
      user = fixture_user()

      attrs = %{
        "capacity" => 4,
        "deadline" => "",
        "description" => "some description",
        "event_date" => "",
        "master_id" => user.id,
        "name" => "some name",
        "type" => 1,
        "join" => false,
        "url" => "some url",
        "platform" => 1
      }

      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: "")

      assert json_response(conn, 200)["result"]
    end

    test "renders errors when data is mostly nil", %{conn: conn} do
      conn = post(conn, Routes.tournament_path(conn, :create), tournament: @invalid_attrs, file: "")

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
      #assert json_response(conn, 200)["error"] == "Undefined User"
      assert json_response(conn, 200)["error"] == "master_id does not exist, "
      refute json_response(conn, 200)["result"]
    end

    test "create tournament (custom details)", %{conn: conn} do
      user = fixture_user(num: 2)

      attrs = %{
        "capacity" => 42,
        "deadline" => "2010-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2010-04-17T14:00:00Z",
        "master_id" => user.id,
        "name" => "some name",
        "type" => 1,
        "join" => "true",
        "enabled_coin_toss" => "true",
        "coin_head_field" => "omote",
        "coin_tail_field" => "ura",
        "enabled_map" => "true",
        "url" => "some url",
        "platform" => 1,
        "rule" => "flipban"
      }

      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: "")

      assert json_response(conn, 200)["result"]

      conn
      |> json_response(200)
      |> Map.get("data")
      |> Map.get("id")
      |> Tournaments.get_custom_detail_by_tournament_id()
      ~> detail

      assert detail.coin_head_field == "omote"
      assert detail.coin_tail_field == "ura"
    end

    test "create tournament (multiple selection)", %{conn: conn} do
      user = fixture_user(num: 2)

      attrs = %{
        "capacity" => 42,
        "deadline" => "2010-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2010-04-17T14:00:00Z",
        "master_id" => user.id,
        "name" => "some name",
        "type" => 1,
        "join" => "true",
        "enabled_coin_toss" => "true",
        "enabled_map" => "true",
        "coin_head_field" => "omote",
        "coin_tail_field" => "ura",
        "url" => "some url",
        "platform" => 1,
        "rule" => "flipban"
      }

      options = [
        %{"name" => "test selection1"},
        %{"name" => "test selection2"},
        %{"name" => "test selection3"}
      ]

      conn =
        post(conn, Routes.tournament_path(conn, :create),
          tournament: attrs,
          file: "",
          maps: options
        )

      assert json_response(conn, 200)["result"]

      conn
      |> json_response(200)
      |> Map.get("data")
      |> Map.get("id")
      ~> id

      conn = get(conn, Routes.tournament_path(conn, :show), tournament_id: id)

      conn
      |> json_response(200)
      |> Map.get("data")
      |> Map.get("maps")
      |> Enum.map(fn selection ->
        assert is_binary(selection["name"])
        assert is_integer(selection["id"])
        assert selection["state"] == "not_selected"
      end)
      |> length()
      |> Kernel.==(3)
      |> assert()

      assert json_response(conn, 200)["data"]["enabled_map"]
    end
  end

  describe "create basic tournament" do
    test "individual works", %{conn: conn} do
      user = fixture_user()
      attrs = %{
        "capacity" => 4,
        "deadline" => "2050-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2050-04-17T14:00:00Z",
        "enabled_map" => false,
        "enabled_coin_toss" => false,
        "master_id" => user.id,
        "name" => "some name",
        "type" => 1,
        "url" => "some url",
        "platform" => 1,
        "rule" => "basic"
      }

      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: "")
      assert json_response(conn, 200)["result"]

      attrs = %{
        "capacity" => 4,
        "deadline" => "2050-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2050-04-17T14:00:00Z",
        "master_id" => user.id,
        "name" => "some name",
        "type" => 1,
        "url" => "some url",
        "platform" => 1,
        "rule" => "basic"
      }
      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: "")
      assert json_response(conn, 200)["result"]
    end

    test "individual does not work", %{conn: conn} do
      user = fixture_user()
      attrs = %{
        "capacity" => 4,
        "deadline" => "2050-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2050-04-17T14:00:00Z",
        "enabled_map" => true,
        "enabled_coin_toss" => true,
        "master_id" => user.id,
        "name" => "some name",
        "type" => 1,
        "url" => "some url",
        "platform" => 1,
        "rule" => "basic"
      }

      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: "")
      refute json_response(conn, 200)["result"]
    end

    test "team works", %{conn: conn} do
      user = fixture_user()
      attrs = %{
        "capacity" => 4,
        "deadline" => "2050-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2050-04-17T14:00:00Z",
        "enabled_map" => false,
        "enabled_coin_toss" => false,
        "master_id" => user.id,
        "name" => "some name",
        "type" => 1,
        "is_team" => true,
        "url" => "some url",
        "platform" => 1,
        "rule" => "basic"
      }

      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: "")
      assert json_response(conn, 200)["result"]
    end

    test "team does not work", %{conn: conn} do
      user = fixture_user()
      attrs = %{
        "capacity" => 4,
        "deadline" => "2050-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2050-04-17T14:00:00Z",
        "enabled_map" => true,
        "enabled_coin_toss" => true,
        "master_id" => user.id,
        "name" => "some name",
        "type" => 1,
        "url" => "some url",
        "platform" => 1,
        "rule" => "basic"
      }

      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: "")
      refute json_response(conn, 200)["result"]
    end
  end

  describe "create flipban tournament" do
    test "individual works", %{conn: conn} do
      user = fixture_user()
      attrs = %{
        "capacity" => 4,
        "coin_head_field" => "map選択",
        "coin_tail_field" => "a/d選択",
        "deadline" => "2050-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2050-04-17T14:00:00Z",
        "enabled_map" => true,
        "enabled_coin_toss" => true,
        "master_id" => user.id,
        "name" => "some name",
        "type" => 1,
        "url" => "some url",
        "platform" => 1,
        "rule" => "flipban"
      }

      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: "")
      assert json_response(conn, 200)["result"]
    end

    test "individual without coin_fields does not work", %{conn: conn} do
      user = fixture_user()
      attrs = %{
        "capacity" => 4,
        "deadline" => "2050-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2050-04-17T14:00:00Z",
        "enabled_map" => true,
        "enabled_coin_toss" => true,
        "master_id" => user.id,
        "name" => "some name",
        "type" => 1,
        "url" => "some url",
        "platform" => 1,
        "rule" => "flipban"
      }

      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: "")
      refute json_response(conn, 200)["result"]
    end

    test "individual without enabling maps and coin_toss does not work", %{conn: conn} do
      user = fixture_user()
      attrs = %{
        "capacity" => 4,
        "coin_head_field" => "map選択",
        "coin_tail_field" => "a/d選択",
        "deadline" => "2050-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2050-04-17T14:00:00Z",
        "master_id" => user.id,
        "name" => "some name",
        "type" => 1,
        "url" => "some url",
        "platform" => 1,
        "rule" => "flipban"
      }

      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: "")
      refute json_response(conn, 200)["result"]

      attrs = %{
        "capacity" => 4,
        "coin_head_field" => "map選択",
        "coin_tail_field" => "a/d選択",
        "deadline" => "2050-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2050-04-17T14:00:00Z",
        "enabled_map" => false,
        "enabled_coin_toss" => false,
        "master_id" => user.id,
        "name" => "some name",
        "type" => 1,
        "url" => "some url",
        "platform" => 1,
        "rule" => "flipban"
      }

      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: "")
      refute json_response(conn, 200)["result"]
    end

    test "team works", %{conn: conn} do
      user = fixture_user()
      attrs = %{
        "capacity" => 4,
        "coin_head_field" => "map選択",
        "coin_tail_field" => "a/d選択",
        "deadline" => "2050-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2050-04-17T14:00:00Z",
        "enabled_map" => true,
        "enabled_coin_toss" => true,
        "master_id" => user.id,
        "name" => "some name",
        "type" => 1,
        "url" => "some url",
        "is_team" => true,
        "platform" => 1,
        "rule" => "flipban"
      }

      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: "")
      assert json_response(conn, 200)["result"]
    end

    test "team without coin_fields does not work", %{conn: conn} do
      user = fixture_user()
      attrs = %{
        "capacity" => 4,
        "deadline" => "2050-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2050-04-17T14:00:00Z",
        "enabled_map" => true,
        "enabled_coin_toss" => true,
        "master_id" => user.id,
        "name" => "some name",
        "is_team" => true,
        "type" => 1,
        "url" => "some url",
        "platform" => 1,
        "rule" => "flipban"
      }

      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: "")
      refute json_response(conn, 200)["result"]
    end

    test "team without enabling maps and coin_toss does not work", %{conn: conn} do
      user = fixture_user()
      attrs = %{
        "capacity" => 4,
        "coin_head_field" => "map選択",
        "coin_tail_field" => "a/d選択",
        "deadline" => "2050-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2050-04-17T14:00:00Z",
        "master_id" => user.id,
        "name" => "some name",
        "is_team" => true,
        "type" => 1,
        "url" => "some url",
        "platform" => 1,
        "rule" => "flipban"
      }

      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: "")
      refute json_response(conn, 200)["result"]

      attrs = %{
        "capacity" => 4,
        "coin_head_field" => "map選択",
        "coin_tail_field" => "a/d選択",
        "deadline" => "2050-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2050-04-17T14:00:00Z",
        "enabled_map" => false,
        "enabled_coin_toss" => false,
        "master_id" => user.id,
        "name" => "some name",
        "is_team" => true,
        "type" => 1,
        "url" => "some url",
        "platform" => 1,
        "rule" => "flipban"
      }

      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: "")
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

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

      conn = post(conn, Routes.tournament_path(conn, :delete_loser), tournament: %{"tournament_id" => tournament.id, "loser_list" => [entrant.user_id]})

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
            # assert data["platform"] == tournament.platform
            assert is_nil(data["password"])
            assert data["capacity"] == tournament.capacity
            assert data["master_id"] == tournament.master_id
            assert data["url"] == tournament.url
          end).()

      assert Progress.get_duplicate_users(tournament.id) == []
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

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

      conn = post(conn, Routes.tournament_path(conn, :delete_loser), tournament: %{"tournament_id" => tournament.id, "loser_list" => [entrant.user_id]})

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

  describe "get tournament (team)" do
    defp setup_team(n) do
      tournament = fixture_tournament(is_started: false, is_team: true, capacity: 2)
      assert tournament.team_size == 5

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

    test "get tournament (is team)", %{conn: conn} do
      {tournament, users} = setup_team(5)
      [leader | users] = users

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

      conn = get(conn, Routes.tournament_path(conn, :show), tournament_id: tournament.id)

      json_response(conn, 200)
      |> Map.get("data")
      |> Map.get("teams")
      |> Enum.map(fn team ->
        assert team["is_confirmed"]
        assert team["size"] == 5
      end)
      |> length()
      |> Kernel.==(1)
      |> assert()

      assert json_response(conn, 200)["data"]["team_size"] == 5

      users =
        6..10
        |> Enum.to_list()
        |> Enum.map(fn n ->
          fixture_user(num: n)
        end)
        |> Enum.map(fn user ->
          user.id
        end)

      [leader | members] = users
      size = 5

      Tournaments.create_team(tournament.id, size, leader, members)

      conn = get(conn, Routes.tournament_path(conn, :show), tournament_id: tournament.id)

      json_response(conn, 200)
      |> Map.get("data")
      |> Map.get("teams")
      |> Enum.map(fn team ->
        assert team["is_confirmed"]
        assert team["size"] == 5
      end)
      |> length()
      |> Kernel.==(1)
      |> assert()
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

      Timex.now()
      |> Timex.add(Timex.Duration.from_days(1))
      ~> date_offset

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
        "url" => "some url",
        "platform" => 1
      }

      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: "")
      id = json_response(conn, 200)["data"]["id"]

      conn = post(conn, Routes.entrant_path(conn, :create), %{"entrant" => %{"tournament_id" => id, "user_id" => user.id}})

      conn
      |> get(Routes.tournament_path(conn, :home), filter: "entry", user_id: user.id)
      |> json_response(200)
      |> Map.get("data")
      |> Enum.map(fn tournament ->
        assert tournament["id"] == id
      end)
      |> length()
      |> then(fn len ->
        assert len == 1
      end)
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
      conn = post(conn, Routes.tournament_path(conn, :delete, %{"tournament_id" => tournament.id}))

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

      conn = post(conn, Routes.assistant_path(conn, :create), assistant: %{tournament_id: assistant_tournament.id, user_id: [tournament.master_id]})

      Enum.each(tournaments, fn t ->
        Map.new()
        |> Map.put("rank", 0)
        |> Map.put("tournament_id", t.id)
        |> Map.put("user_id", tournament.master_id)
        |> Tournaments.create_entrant()
      end)

      tournaments
      |> Enum.map(fn tournament ->
        tournament.id
      end)
      |> Enum.concat([tournament.id])
      |> Enum.concat([assistant_tournament.id])
      ~> tournament_id_list

      conn = get(conn, Routes.tournament_path(conn, :relevant, %{"user_id" => tournament.master_id}))

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

    test "works (team)", %{conn: conn} do
      # leader, member, entrant, master

      # member
      100..105
      |> Enum.to_list()
      |> Enum.map(fn n ->
        [num: n]
        |> fixture_user()
        |> Map.get(:id)
      end)
      ~> [leader | member]

      member
      |> hd()
      |> Accounts.get_user()
      ~> me

      [is_team: true, capacity: 2, num: 5]
      |> fixture_tournament()
      ~> member_tournament
      |> Map.get(:id)
      |> Tournaments.create_team(5, leader, member)
      |> elem(1)
      |> Map.get(:team_member)
      |> Enum.filter(&(!&1.is_invitation_confirmed))
      |> Enum.map(fn member ->
        member
        |> Map.get(:user_id)
        |> Tournaments.get_team_invitations_by_user_id()
        |> hd()
        |> Map.get(:id)
        |> Tournaments.confirm_team_invitation()
      end)

      # leader
      member_tournament.id
      |> Tournaments.get_confirmed_teams()
      |> length()
      |> Kernel.==(1)
      |> assert()

      60..64
      |> Enum.to_list()
      |> Enum.map(fn n ->
        [num: n]
        |> fixture_user()
        |> Map.get(:id)
      end)
      ~> members

      [is_team: true, capacity: 2, num: 50]
      |> fixture_tournament()
      |> Map.get(:id)
      |> Tournaments.create_team(5, me.id, members)
      |> elem(1)
      |> Map.get(:team_member)
      |> Enum.filter(&(&1.user_id != me.id))
      |> Enum.map(fn member ->
        member
        |> Map.get(:user_id)
        |> Tournaments.get_team_invitations_by_user_id()
        |> hd()
        |> Map.get(:id)
        |> Tournaments.confirm_team_invitation()
      end)

      # entrant
      [capacity: 2, num: 500]
      |> fixture_tournament()
      ~> entrant_tournament

      Map.new()
      |> Map.put(:tournament_id, entrant_tournament.id)
      |> Map.put(:user_id, me.id)
      |> Tools.atom_map_to_string_map()
      |> Tournaments.create_entrant()

      # master
      [master_id: me.id, num: 5000]
      |> fixture_tournament()

      conn
      |> get(Routes.tournament_path(conn, :relevant, %{"user_id" => me.id}))
      |> json_response(200)
      |> Map.get("data")
      |> length()
      |> Kernel.==(4)
      |> assert()
    end
  end

  describe "pending tournaments" do
    test "works", %{conn: conn} do
      tournament = fixture_tournament(is_team: true, type: 2)

      [num: 5]
      |> fixture_user()
      |> Map.get(:id)
      ~> user_id

      6..10
      |> Enum.to_list()
      |> Enum.map(fn n ->
        [num: n]
        |> fixture_user()
        |> Map.get(:id)
      end)
      ~> member_id_list

      conn =
        post(
          conn,
          Routes.team_path(conn, :create),
          tournament_id: tournament.id,
          size: tournament.team_size,
          leader_id: user_id,
          user_id_list: member_id_list
        )

      assert json_response(conn, 200)["result"]

      conn =
        get(
          conn,
          Routes.tournament_path(conn, :pending),
          user_id: user_id
        )

      assert json_response(conn, 200)["result"]

      conn
      |> json_response(200)
      |> Map.get("data")
      |> Enum.map(fn t ->
        assert t["id"] == tournament.id
      end)
      |> length()
      |> Kernel.==(1)
      |> assert()

      member_id_list
      |> Enum.each(fn member ->
        member
        |> Tournaments.get_team_invitations_by_user_id()
        |> Enum.each(fn invitation ->
          invitation
          |> Map.get(:id)
          |> Tournaments.confirm_team_invitation()
        end)
      end)

      conn =
        get(
          conn,
          Routes.tournament_path(conn, :pending),
          user_id: user_id
        )

      assert json_response(conn, 200)["result"]

      conn
      |> json_response(200)
      |> Map.get("data")
      |> length()
      |> Kernel.==(0)
      |> assert()
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
      refute json_response(conn, 200)["has_requested_as_team"]
      refute json_response(conn, 200)["has_confirmed_as_team"]

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
      refute json_response(conn, 200)["has_requested_as_team"]
      refute json_response(conn, 200)["has_confirmed_as_team"]
    end

    test "team", %{conn: conn} do
      tournament = fixture_tournament(is_team: true, capacity: 1, deadline: "2100-04-17T14:00:00Z")

      1..5
      |> Enum.to_list()
      |> Enum.map(fn n ->
        fixture_user(num: n)
      end)
      |> Enum.map(fn user ->
        user.id
      end)
      ~> users

      [leader | members] = users
      size = 5

      conn =
        get(conn, Routes.tournament_path(conn, :is_able_to_join), %{
          user_id: leader,
          tournament_id: tournament.id
        })

      assert json_response(conn, 200)["result"]
      refute json_response(conn, 200)["has_requested_as_team"]
      refute json_response(conn, 200)["has_confirmed_as_team"]

      Tournaments.create_team(tournament.id, size, leader, members)

      conn =
        get(conn, Routes.tournament_path(conn, :is_able_to_join), %{
          user_id: leader,
          tournament_id: tournament.id
        })

      refute json_response(conn, 200)["result"]
      assert json_response(conn, 200)["has_requested_as_team"]
      refute json_response(conn, 200)["has_confirmed_as_team"]

      user = fixture_user(num: 100)

      conn =
        get(conn, Routes.tournament_path(conn, :is_able_to_join), %{
          user_id: user.id,
          tournament_id: tournament.id
        })

      assert json_response(conn, 200)["result"]

      fill_with_team(tournament.id)

      conn =
        get(conn, Routes.tournament_path(conn, :is_able_to_join), %{
          user_id: user.id,
          tournament_id: tournament.id
        })

      refute json_response(conn, 200)["result"]
    end

    test "team (confirmed)", %{conn: conn} do
      tournament = fixture_tournament(num: 2, is_team: true, type: 2)

      tournament.id
      |> fill_with_team()
      |> hd()
      |> Map.get(:id)
      |> Tournaments.get_leader()
      ~> leader

      conn =
        get(conn, Routes.tournament_path(conn, :is_able_to_join), %{
          user_id: leader.user_id,
          tournament_id: tournament.id
        })

      refute json_response(conn, 200)["result"]
      assert json_response(conn, 200)["has_requested_as_team"]
      assert json_response(conn, 200)["has_confirmed_as_team"]
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
      assert json_response(conn, 200)["data"]["id"] == tournament["id"]

      conn = get(conn, Routes.tournament_path(conn, :is_started_at_least_one), user_id: user2.id)
      refute json_response(conn, 200)["result"]
      assert is_nil(json_response(conn, 200)["data"]["id"])

      Tournaments.create_entrant(%{
        "rank" => 0,
        "tournament_id" => tournament["id"],
        "user_id" => user2.id
      })

      conn = get(conn, Routes.tournament_path(conn, :is_started_at_least_one), user_id: user2.id)
      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["data"]["id"] == tournament["id"]
    end

    test "works (team)", %{conn: conn} do
      tournament = fixture_tournament(is_team: true, type: 2, capacity: 2)
      teams = fill_with_team(tournament.id)

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

      teams
      |> hd()
      |> Map.get(:id)
      |> Tournaments.get_leader()
      |> Map.get(:user)
      ~> me

      tournament.id
      |> Tournaments.get_teammates(me.id)
      |> Enum.filter(fn member ->
        !member.is_leader
      end)
      |> hd()
      |> Map.get(:user)
      ~> mate

      conn = get(conn, Routes.tournament_path(conn, :is_started_at_least_one), user_id: me.id)
      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["data"]["id"] == tournament.id

      conn = get(conn, Routes.tournament_path(conn, :is_started_at_least_one), user_id: mate.id)
      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["data"]["id"] == tournament.id
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

      conn
      |> json_response(200)
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
      |> then(fn len ->
        assert len == 3
      end)
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

      conn
      |> json_response(200)
      |> Map.get("data")
      |> Enum.map(fn tab ->
        assert Enum.member?(tab_name_list, tab["topic_name"])
      end)
      |> length()
      |> then(fn len ->
        assert len == 2
      end)
    end
  end

  describe "start tournament" do
    setup [:create_tournament]

    test "start a tournament with valid data (type: 1)", %{conn: conn, tournament: _tournament} do
      tournament = fixture_tournament(capacity: 12, num: 1000)
      create_entrants(12, tournament.id)

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

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

      {:ok, user} = Accounts.create_user(%{"name" => "type2name", "email" => "type2e@mail.com", "password" => "Password123"})
      {:ok, tournament} = Tournaments.create_tournament(%{create_attrs2 | "master_id" => user.id})

      entrants = create_entrants(8, tournament.id)
      entrant_id_list = Enum.map(entrants, fn entrant -> entrant.user_id end)

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

      json_response(conn, 200)
      |> Map.get("data")
      |> Map.get("match_list")
      |> List.flatten()
      |> Enum.map(fn user_id ->
        assert user_id in entrant_id_list
      end)
      |> length()
      |> then(fn len ->
          assert len == length(entrants)
        end)

      tournament.id
      |> Progress.get_match_list()
      |> List.flatten()
      |> Enum.map(fn user_id ->
        assert user_id in entrant_id_list
      end)
      |> length()
      |> then(fn len ->
        assert len == length(entrants)
      end)

      tournament.id
      |> Progress.get_match_list_with_fight_result()
      |> List.flatten()
      |> length()
      |> then(fn len ->
        assert len == length(entrants)
      end)
    end
  end

  describe "delete loser" do
    setup [:create_tournament]

    test "works", %{conn: conn, tournament: tournament} do
      entrants = create_entrants(8, tournament.id)

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

      match_list = json_response(conn, 200)["data"]["match_list"]

      # TODO: redisの確認もしておきたい
      losers = [hd(entrants).user_id]

      conn = post(conn, Routes.tournament_path(conn, :delete_loser), tournament: %{tournament_id: tournament.id, loser_list: losers})

      json_response(conn, 200)
      |> Map.get("updated_match_list")
      |> then(fn list ->
        old_len =
          match_list
          |> List.flatten()
          |> length()

        new_len =
          list
          |> List.flatten()
          |> length()

        assert new_len == old_len - 1
      end)

      Progress.get_single_tournament_match_logs(tournament.id, hd(losers))
      |> Enum.map(fn log ->
        assert log.loser_id == hd(losers)
        assert log.tournament_id == tournament.id
      end)
      |> length()
      |> then(fn len ->
        assert len == 1
      end)

      assert Progress.get_fight_result(hd(losers), tournament.id) == nil
      assert is_nil(Progress.get_match_pending_list(hd(losers), tournament.id))

      tournament.id
      |> Progress.get_match_list()
      |> List.flatten()
      |> Enum.any?(fn user_id ->
        user_id == hd(losers)
      end)
      |> (fn bool ->
            refute bool
          end).()

      tournament.id
      |> Progress.get_match_list_with_fight_result()
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

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

      match_list = json_response(conn, 200)["data"]["match_list"]

      # TODO: redisの確認もしておきたい
      losers = hd(entrants).user_id

      conn = post(conn, Routes.tournament_path(conn, :delete_loser), tournament: %{tournament_id: tournament.id, loser_list: losers})

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

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

      match_list = json_response(conn, 200)["data"]["match_list"]

      # TODO: redisの確認もしておきたい
      losers =
        entrants
        |> hd()
        |> Map.get(:user_id)
        |> to_string()

      conn = post(conn, Routes.tournament_path(conn, :delete_loser), tournament: %{tournament_id: tournament.id, loser_list: losers})

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

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

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

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

      user_id_list = Enum.map(entrants, fn entrant -> entrant.user_id end)

      conn = get(conn, Routes.tournament_path(conn, :get_match_list), tournament_id: tournament.id)

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

  describe "get options" do
    test "works", %{conn: conn} do
      tournament = fixture_tournament()

      1..5
      |> Enum.to_list()
      |> Enum.each(fn n ->
        %{"name" => "#{n}test", "tournament_id" => tournament.id, "icon_path" => "a"}
        |> Tournaments.create_map()
      end)

      conn = get(conn, Routes.tournament_path(conn, :maps), tournament_id: tournament.id)

      conn
      |> json_response(200)
      |> Map.get("data")
      |> Enum.map(fn option ->
        assert is_binary(option["name"])
        assert is_binary(option["icon_path"])
        refute is_nil(option["id"])
        assert is_binary(option["state"])
      end)
      |> length()
      |> Kernel.==(5)
      |> assert()
    end
  end

  describe "start match" do
    setup [:create_tournament]

    test "works", %{conn: conn, tournament: tournament} do
      entrants = create_entrants(8, tournament.id)

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

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
        |> Progress.get_match_pending_list_of_tournament()
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

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

      conn =
        get(conn, Routes.tournament_path(conn, :get_opponent), %{
          "tournament_id" => tournament.id,
          "user_id" => hd(entrants).user_id
        })

      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["opponent"]
    end

    test "get an opponent team", %{conn: conn} do
      [is_team: true, capacity: 4, num: 900, type: 2]
      |> fixture_tournament()
      ~> tournament
      |> Map.get(:id)
      |> fill_with_team()
      |> hd()
      ~> my_team

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

      assert json_response(conn, 200)["result"]

      tournament.id
      |> Progress.get_match_list()
      |> List.flatten()
      |> length()
      |> Kernel.==(4)
      |> assert()

      conn =
        get(conn, Routes.tournament_path(conn, :get_opponent),
          tournament_id: tournament.id,
          team_id: my_team.id
        )

      assert json_response(conn, 200)["result"]
      # opponent = json_response(conn, 200)["opponent"]
    end
  end

  describe "get fighting users" do
    setup [:create_tournament]

    test "get fighting users", %{conn: conn, tournament: tournament} do
      entrants = create_entrants(8, tournament.id)
      player = hd(entrants)

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

      conn =
        get(conn, Routes.tournament_path(conn, :get_opponent), %{
          "tournament_id" => tournament.id,
          "user_id" => player.user_id
        })

      opponent = json_response(conn, 200)["opponent"]

      conn = get(conn, Routes.tournament_path(conn, :get_fighting_users), tournament_id: tournament.id)

      assert json_response(conn, 200)["data"] == []

      conn =
        post(conn, Routes.tournament_path(conn, :start_match),
          user_id: player.user_id,
          tournament_id: tournament.id
        )

      assert json_response(conn, 200)["result"]

      conn = get(conn, Routes.tournament_path(conn, :get_fighting_users), tournament_id: tournament.id)

      assert length(json_response(conn, 200)["data"]) == 1

      conn =
        post(conn, Routes.tournament_path(conn, :start_match),
          user_id: opponent["id"],
          tournament_id: tournament.id
        )

      assert json_response(conn, 200)["result"]

      conn = get(conn, Routes.tournament_path(conn, :get_fighting_users), tournament_id: tournament.id)

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

      conn = get(conn, Routes.tournament_path(conn, :get_fighting_users), tournament_id: tournament.id)

      assert Enum.empty?(json_response(conn, 200)["data"])
    end

    test "get fighting and waiting users (team)", %{conn: conn} do
      [is_team: true, capacity: 4, num: 10, type: 2]
      |> fixture_tournament()
      ~> tournament
      |> Map.get(:id)
      |> fill_with_team()
      ~> teams
      |> Enum.map(fn team ->
        team.id
      end)
      ~> team_id_list

      my_team = hd(teams)

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

      conn =
        get(conn, Routes.tournament_path(conn, :get_opponent), %{
          "tournament_id" => tournament.id,
          "team_id" => my_team.id
        })

      conn = get(conn, Routes.tournament_path(conn, :get_fighting_users), tournament_id: tournament.id)

      assert json_response(conn, 200)["result"]

      conn
      |> json_response(200)
      |> Map.get("data")
      |> length()
      |> Kernel.==(0)
      |> assert()

      conn = get(conn, Routes.tournament_path(conn, :get_waiting_users), tournament_id: tournament.id)

      assert json_response(conn, 200)["result"]

      conn
      |> json_response(200)
      |> Map.get("data")
      |> Enum.map(fn team ->
        assert team["id"] in team_id_list
      end)
      |> length()
      |> Kernel.==(4)
      |> assert()

      my_member = hd(my_team.team_member)

      conn =
        post(conn, Routes.tournament_path(conn, :start_match),
          user_id: my_member.user_id,
          tournament_id: tournament.id
        )

      assert json_response(conn, 200)["result"]

      conn = get(conn, Routes.tournament_path(conn, :get_fighting_users), tournament_id: tournament.id)

      assert length(json_response(conn, 200)["data"]) == 1

      conn = get(conn, Routes.tournament_path(conn, :get_waiting_users), tournament_id: tournament.id)

      assert length(json_response(conn, 200)["data"]) == 3
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

      conn = get(conn, Routes.tournament_path(conn, :get_waiting_users), tournament_id: tournament.id)

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

      conn = get(conn, Routes.tournament_path(conn, :get_waiting_users), tournament_id: tournament.id)

      assert length(json_response(conn, 200)["data"]) == length(entrants) - 1

      conn =
        post(conn, Routes.tournament_path(conn, :start_match),
          user_id: opponent["id"],
          tournament_id: tournament.id
        )

      assert json_response(conn, 200)["result"]

      conn = get(conn, Routes.tournament_path(conn, :get_waiting_users), tournament_id: tournament.id)

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

      # conn = post(conn, Routes.tournament_path(conn, :delete_loser), tournament: %{tournament_id: tournament.id, loser_list: [opponent["id"]]})

      conn = get(conn, Routes.tournament_path(conn, :get_waiting_users), tournament_id: tournament.id)

      assert length(json_response(conn, 200)["data"]) == length(entrants) - 1
    end
  end

  describe "check pending" do
    setup [:create_tournament]

    test "works", %{conn: conn, tournament: tournament} do
      entrants = create_entrants(8, tournament.id)

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

      user1_id = hd(entrants).user_id

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
    test "works", %{conn: conn} do
      tournament = fixture_tournament()
      create_entrants(8, tournament.id)

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

      conn = get(conn, Routes.tournament_path(conn, :get_match_list), %{"tournament_id" => tournament.id})
      match_list = json_response(conn, 200)["match_list"]

      match_list
      |> List.flatten()
      |> Enum.chunk_every(2)
      |> hd()
      ~> [user1_id, user2_id]

      conn =
        get(conn, Routes.tournament_path(conn, :has_lost?),
          user_id: user1_id,
          tournament_id: tournament.id
        )

      refute json_response(conn, 200)["has_lost"]


      conn = post(conn, Routes.tournament_path(conn, :start_match), %{"user_id" => user1_id, "tournament_id" => tournament.id})
      conn = post(conn, Routes.tournament_path(conn, :start_match), %{"user_id" => user2_id, "tournament_id" => tournament.id})

      conn =
        post(conn, Routes.tournament_path(conn, :claim_win),
          opponent_id: user1_id,
          user_id: user2_id,
          tournament_id: tournament.id
        )

      conn =
        post(conn, Routes.tournament_path(conn, :claim_lose),
          opponent_id: user2_id,
          user_id: user1_id,
          tournament_id: tournament.id
        )

      # conn = post(conn, Routes.tournament_path(conn, :delete_loser), tournament: %{"tournament_id" => tournament.id, "loser_list" => [user1_id]})

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

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

      conn =
        get(conn, Routes.tournament_path(conn, :state),
          tournament_id: tournament.id,
          user_id: user1_id
        )

      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["state"] == "ShouldStartMatch"

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
      assert json_response(conn, 200)["state"] == "IsWaitingForStartMatch"

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

      # conn = post(conn, Routes.tournament_path(conn, :delete_loser), tournament: %{"tournament_id" => tournament.id, "loser_list" => [opponent1_id]})

      conn =
        get(conn, Routes.tournament_path(conn, :state),
          tournament_id: tournament.id,
          user_id: user1_id
        )

      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["state"] == "IsAlone"
    end
  end

  describe "state machine with controller" do
    test "basic (individual)", %{conn: conn} do
      user = fixture_user()
      attrs = %{
        "capacity" => 8,
        "deadline" => "2010-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2010-04-17T14:00:00Z",
        "master_id" => user.id,
        "name" => "some name",
        "type" => 1,
        "join" => "false",
        "url" => "some url",
        "platform" => 1,
        "rule" => "basic"
      }

      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: "")

      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["data"]["rule"] == "basic"
      refute json_response(conn, 200)["data"]["is_team"]

      master_id = json_response(conn, 200)["data"]["master_id"]
      tournament_id = json_response(conn, 200)["data"]["id"]
      capacity = json_response(conn, 200)["data"]["capacity"]

      conn = get(conn, Routes.tournament_path(conn, :show), %{"tournament_id" => tournament_id})
      refute json_response(conn, 200)["data"]["is_started"]

      10..10 + capacity - 1
      |> Enum.to_list()
      |> Enum.map(&fixture_user(num: &1))
      |> Enum.map(fn user ->
        conn = post(conn, Routes.entrant_path(conn, :create), %{"entrant" => %{"tournament_id" => tournament_id, "user_id" => user.id}})
        json_response(conn, 200)
        assert json_response(conn, 200)["result"]
        user
      end)
      ~> user_id_list
      |> then(fn list ->
        assert length(list) == capacity
      end)

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => user.id})
      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["state"] == "IsNotStarted"

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => master_id, "tournament_id" => tournament_id})

      assert json_response(conn, 200)["result"]
      match_list = json_response(conn, 200)["data"]["match_list"]

      conn
      |> json_response(200)
      |> Map.get("data")
      |> Map.get("messages")
      |> then(fn messages ->
        # NOTE: masterの分を加算して+1
        assert length(messages) == capacity + 1
      end)

      conn = get(conn, Routes.tournament_path(conn, :show), %{"tournament_id" => tournament_id})
      assert json_response(conn, 200)["data"]["is_started"]

      # NOTE: Manager
      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => user.id})
      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["state"] == "IsManager"
      assert is_nil(json_response(conn, 200)["opponent"])
      assert is_nil(json_response(conn, 200)["score"])

      # NOTE: 第一回戦
      match_list
      |> List.flatten()
      |> then(fn list ->
        assert length(list) == length(user_id_list)
        list
      end)
      |> Enum.chunk_every(2)
      |> then(fn matches ->
        assert length(matches) == length(user_id_list) / 2
        matches
      end)
      |> Enum.each(fn [user1_id, user2_id] ->
        basic_fight(conn, user1_id, user2_id, tournament_id)
      end)

      conn = get(conn, Routes.tournament_path(conn, :get_match_list), %{"tournament_id" => tournament_id})
      assert json_response(conn, 200)["result"]
      match_list = json_response(conn, 200)["match_list"]

      # NOTE: 第二回戦
      match_list
      |> List.flatten()
      |> then(fn list ->
        assert length(list) == length(user_id_list) / 2
        list
      end)
      |> Enum.chunk_every(2)
      |> Enum.each(fn [user1_id, user2_id] ->
        basic_fight(conn, user1_id, user2_id, tournament_id)
      end)

      conn = get(conn, Routes.tournament_path(conn, :get_match_list), %{"tournament_id" => tournament_id})
      assert json_response(conn, 200)["result"]
      [user1_id, user2_id] = json_response(conn, 200)["match_list"]

      # NOTE: 対戦相手がマッチをスタートしていないのにclaim_win/loseしようとするとどうなるか
      conn = post(conn, Routes.tournament_path(conn, :start_match), %{"user_id" => user1_id, "tournament_id" => tournament_id})
      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["rule"] == "basic"

      conn
      |> json_response(200)
      |> Map.get("messages")
      |> Enum.empty?()
      |> refute()

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => user1_id})
      assert json_response(conn, 200)["state"] == "IsWaitingForStartMatch"

      conn = post(conn, Routes.tournament_path(conn, :claim_win), %{"tournament_id" => tournament_id, "user_id" => user1_id, "opponent_id" => user2_id})
      refute json_response(conn, 200)["result"]
      assert json_response(conn, 200)["error"] == "Invalid state"
      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => user1_id})
      assert json_response(conn, 200)["state"] == "IsWaitingForStartMatch"

      conn = post(conn, Routes.tournament_path(conn, :start_match), %{"user_id" => user2_id, "tournament_id" => tournament_id})
      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["rule"] == "basic"

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => user2_id})
      assert json_response(conn, 200)["state"] == "IsPending"
      conn = get(conn, Routes.tournament_path(conn, :state), %{"tournament_id" => tournament_id, "user_id" => user2_id})
      assert json_response(conn, 200)["state"] == "IsPending"
      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => user1_id})
      assert json_response(conn, 200)["state"] == "IsPending"
      conn = get(conn, Routes.tournament_path(conn, :state), %{"tournament_id" => tournament_id, "user_id" => user1_id})
      assert json_response(conn, 200)["state"] == "IsPending"

      # NOTE: 重複報告
      conn = post(conn, Routes.tournament_path(conn, :claim_win), %{"tournament_id" => tournament_id, "user_id" => user1_id, "opponent_id" => user2_id})
      assert json_response(conn, 200)["rule"] == "basic"
      assert json_response(conn, 200)["validated"]
      refute json_response(conn, 200)["completed"]
      refute json_response(conn, 200)["is_finished"]

      conn = post(conn, Routes.tournament_path(conn, :claim_win), %{"tournament_id" => tournament_id, "user_id" => user2_id, "opponent_id" => user1_id})
      refute json_response(conn, 200)["validated"]
      refute json_response(conn, 200)["completed"]
      refute json_response(conn, 200)["is_finished"]

      # NOTE: 大会終了
      conn = post(conn, Routes.tournament_path(conn, :claim_lose), %{"tournament_id" => tournament_id, "user_id" => user2_id, "opponent_id" => user1_id})
      assert json_response(conn, 200)["rule"] == "basic"
      assert json_response(conn, 200)["validated"]
      assert json_response(conn, 200)["completed"]
      assert json_response(conn, 200)["is_finished"]

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => user1_id})
      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["rank"] == 1
      assert json_response(conn, 200)["state"] == "IsFinished"
      assert is_nil(json_response(conn, 200)["opponent"])

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => user.id})
      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["state"] == "IsFinished"
    end

    test "basic (individual) (master is entrant) (until the tournament starts)", %{conn: conn} do
      user = fixture_user()
      attrs = %{
        "capacity" => 4,
        "deadline" => "2010-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2010-04-17T14:00:00Z",
        "master_id" => user.id,
        "name" => "some name",
        "type" => 1,
        "join" => "false",
        "url" => "some url",
        "platform" => 1,
        "rule" => "basic"
      }

      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: "")

      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["data"]["rule"] == "basic"
      refute json_response(conn, 200)["data"]["is_team"]

      master_id = json_response(conn, 200)["data"]["master_id"]
      tournament_id = json_response(conn, 200)["data"]["id"]
      capacity = json_response(conn, 200)["data"]["capacity"]

      # NOTE: masterにも参加させるのでその人数を引く
      10..10 + capacity - 1 - 1
      |> Enum.to_list()
      |> Enum.map(&fixture_user(num: &1))
      |> Enum.map(&(&1.id))
      |> Enum.concat([master_id])
      |> Enum.reverse()
      |> Enum.map(fn user_id ->
        conn = post(conn, Routes.entrant_path(conn, :create), %{"entrant" => %{"tournament_id" => tournament_id, "user_id" => user_id}})
        json_response(conn, 200)
        assert json_response(conn, 200)["result"]
        user
      end)
      |> then(fn list ->
        assert length(list) == capacity
      end)

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => master_id})
      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["state"] == "IsNotStarted"

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => master_id, "tournament_id" => tournament_id})

      assert json_response(conn, 200)["result"]
      match_list = json_response(conn, 200)["data"]["match_list"]

      # NOTE: masterがちゃんと参加できているか確認
      match_list
      |> List.flatten()
      |> Enum.member?(master_id)
      |> assert()

      conn
      |> json_response(200)
      |> Map.get("data")
      |> Map.get("messages")
      |> then(fn messages ->
        assert length(messages) == capacity
      end)

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => master_id})
      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["state"] == "ShouldStartMatch"
    end

    defp basic_fight(conn, user1_id, user2_id, tournament_id) do
      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => user1_id})
      assert json_response(conn, 200)["opponent"]["id"] == user2_id
      assert is_nil(json_response(conn, 200)["score"])
      assert json_response(conn, 200)["state"] == "ShouldStartMatch"
      assert json_response(conn, 200)["rule"] == "basic"
      conn = get(conn, Routes.tournament_path(conn, :state), %{"tournament_id" => tournament_id, "user_id" => user1_id})
      assert json_response(conn, 200)["state"] == "ShouldStartMatch"

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => user2_id})
      assert json_response(conn, 200)["opponent"]["id"] == user1_id
      assert is_nil(json_response(conn, 200)["score"])
      assert json_response(conn, 200)["state"] == "ShouldStartMatch"
      conn = get(conn, Routes.tournament_path(conn, :state), %{"tournament_id" => tournament_id, "user_id" => user2_id})
      assert json_response(conn, 200)["state"] == "ShouldStartMatch"

      conn = post(conn, Routes.tournament_path(conn, :start_match), %{"user_id" => user1_id, "tournament_id" => tournament_id})
      assert json_response(conn, 200)["result"]

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => user1_id})
      assert json_response(conn, 200)["state"] == "IsWaitingForStartMatch"
      conn = get(conn, Routes.tournament_path(conn, :state), %{"tournament_id" => tournament_id, "user_id" => user1_id})
      assert json_response(conn, 200)["state"] == "IsWaitingForStartMatch"

      conn = post(conn, Routes.tournament_path(conn, :start_match), %{"user_id" => user2_id, "tournament_id" => tournament_id})
      assert json_response(conn, 200)["result"]
      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => user2_id})
      assert json_response(conn, 200)["state"] == "IsPending"
      conn = get(conn, Routes.tournament_path(conn, :state), %{"tournament_id" => tournament_id, "user_id" => user2_id})
      assert json_response(conn, 200)["state"] == "IsPending"
      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => user1_id})
      assert json_response(conn, 200)["state"] == "IsPending"
      conn = get(conn, Routes.tournament_path(conn, :state), %{"tournament_id" => tournament_id, "user_id" => user1_id})
      assert json_response(conn, 200)["state"] == "IsPending"

      conn = post(conn, Routes.tournament_path(conn, :claim_win), %{"tournament_id" => tournament_id, "user_id" => user1_id, "opponent_id" => user2_id})
      assert json_response(conn, 200)["validated"]
      refute json_response(conn, 200)["completed"]
      refute json_response(conn, 200)["is_finished"]

      conn = post(conn, Routes.tournament_path(conn, :claim_lose), %{"tournament_id" => tournament_id, "user_id" => user2_id, "opponent_id" => user1_id})
      assert json_response(conn, 200)["validated"]
      assert json_response(conn, 200)["completed"]
      refute json_response(conn, 200)["is_finished"]

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => user2_id})
      assert json_response(conn, 200)["state"] == "IsLoser"
      conn = get(conn, Routes.tournament_path(conn, :state), %{"tournament_id" => tournament_id, "user_id" => user2_id})
      assert json_response(conn, 200)["state"] == "IsLoser"

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => user1_id})
      assert (json_response(conn, 200)["state"] == "IsAlone" or json_response(conn, 200)["state"] == "ShouldStartMatch")
      conn = get(conn, Routes.tournament_path(conn, :state), %{"tournament_id" => tournament_id, "user_id" => user1_id})
      assert json_response(conn, 200)["state"] == "IsAlone" or json_response(conn, 200)["state"] == "ShouldStartMatch"
    end

    test "flipban (team)", %{conn: conn} do
      user = fixture_user()
      attrs = %{
        "capacity" => 4,
        "coin_head_field" => "マップ選択",
        "coin_tail_field" => "a/d選択",
        "deadline" => "2010-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2010-04-17T14:00:00Z",
        "master_id" => user.id,
        "name" => "some name",
        "join" => "false",
        "url" => "some url",
        "platform" => 1,
        "is_team" => "true",
        "rule" => "flipban",
        "team_size" => 5,
        "type" => 2,
        # XXX: ここあとでvalidateに追加しないと head_fieldとかもいるかも
        "enabled_map" => "true",
        "enabled_coin_toss" => "true"
      }

      maps = [
        %{"name" => "map1"},
        %{"name" => "map2"},
        %{"name" => "map3"},
        %{"name" => "map4"},
        %{"name" => "map5"},
        %{"name" => "map6"}
      ]

      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: nil, maps: maps)
      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["data"]["rule"] == "flipban"
      assert json_response(conn, 200)["data"]["is_team"]
      assert json_response(conn, 200)["data"]["enabled_map"]
      assert json_response(conn, 200)["data"]["enabled_coin_toss"]

      master_id = json_response(conn, 200)["data"]["master_id"]
      tournament_id = json_response(conn, 200)["data"]["id"]
      capacity = json_response(conn, 200)["data"]["capacity"]
      team_size = json_response(conn, 200)["data"]["team_size"]

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => master_id})
      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["state"] == "IsNotStarted"

      10..10 + capacity * team_size - 1
      |> Enum.to_list()
      |> Enum.map(&fixture_user(num: &1).id)
      |> Enum.chunk_every(team_size)
      |> Enum.map(fn [leader_id | member_id_list] ->
        conn = post(conn, Routes.team_path(conn, :create), %{"tournament_id" => tournament_id, "leader_id" => leader_id, "user_id_list" => member_id_list, "size" => team_size})
        assert json_response(conn, 200)["result"]
        [leader_id | member_id_list]
        |> Enum.each(fn user_id ->
          conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => user_id})
          assert json_response(conn, 200)["state"] == "IsNotStarted"
        end)

        [leader_id | member_id_list]
      end)
      |> Enum.map(fn [leader_id | member_id_list] ->
        member_id_list
        |> Enum.each(fn user_id ->
          user_id
          |> Tournaments.get_invitations()
          |> Enum.each(fn invitation ->
            conn = post(conn, Routes.team_path(conn, :confirm_invitation), %{"invitation_id" => invitation.id})
            assert json_response(conn, 200)["result"]
          end)
        end)
        [leader_id | member_id_list]
      end)
      ~> all_member_id_list

      conn = get(conn, Routes.team_path(conn, :get_confirmed_teams), %{"tournament_id" => tournament_id})

      # NOTE: チームメンバーの人数を確認
      conn
      |> json_response(200)
      |> Map.get("data")
      |> Enum.map(fn team ->
        team["team_member"]
        |> Enum.each(fn member ->
          assert member["is_invitation_confirmed"]
        end)
      end)
      |> length()
      |> then(&(assert &1 == capacity))

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => master_id})
      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["state"] == "IsNotStarted"

      conn = post(conn, Routes.tournament_path(conn, :start), %{"tournament" => %{"master_id" => master_id, "tournament_id" => tournament_id}})
      assert json_response(conn, 200)["result"]

      conn
      |> json_response(200)
      |> Map.get("data")
      |> Map.get("messages")
      |> then(fn messages ->
        # NOTE: masterの分を加算して+1
        assert length(messages) == team_size * capacity + 1
      end)

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => master_id})
      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["state"] == "IsManager"

      # NOTE: 大会がスタートした直後のすべてのメンバーのstateを確認
      all_member_id_list
      |> Enum.map(fn [leader_id | member_id_list] ->
        conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => leader_id})
        assert json_response(conn, 200)["result"]
        assert json_response(conn, 200)["state"] == "ShouldFlipCoin"
        assert json_response(conn, 200)["is_leader"]

        member_id_list
        |> Enum.map(fn member_id ->
          conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => member_id})
          assert json_response(conn, 200)["result"]
          assert json_response(conn, 200)["state"] == "IsMember"
        end)
        |> length()
        |> then(&(assert &1 == team_size - 1))
      end)

      conn = get(conn, Routes.tournament_path(conn, :get_match_list), %{"tournament_id" => tournament_id})
      assert json_response(conn, 200)["result"]
      match_list = json_response(conn, 200)["match_list"]

      # NOTE: 第1回戦
      match_list
      |> List.flatten()
      |> then(fn list ->
        assert length(list) == capacity
        list
      end)
      |> Enum.map(fn team_id ->
        team_id
        |> Tournaments.get_leader()
        |> Map.get(:user_id)
        ~> leader_id

        {:ok, team_id, leader_id}
      end)
      |> Enum.chunk_every(2)
      |> Enum.each(fn [{:ok, team1_id, leader1_id}, {:ok, team2_id, leader2_id}] ->
        flip_fight(conn, team1_id, leader1_id, team2_id, leader2_id, tournament_id, 1)
      end)

      conn = get(conn, Routes.tournament_path(conn, :get_match_list), %{"tournament_id" => tournament_id})
      assert json_response(conn, 200)["result"]
      match_list = json_response(conn, 200)["match_list"]

      # NOTE: 第2回戦
      match_list
      |> List.flatten()
      |> then(fn list ->
        assert length(list) == capacity / 2
        list
      end)
      |> Enum.map(fn team_id ->
        team_id
        |> Tournaments.get_leader()
        |> Map.get(:user_id)
        ~> leader_id

        {:ok, team_id, leader_id}
      end)
      |> Enum.chunk_every(2)
      |> Enum.each(fn [{:ok, team1_id, leader1_id}, {:ok, team2_id, leader2_id}] ->
        flip_fight(conn, team1_id, leader1_id, team2_id, leader2_id, tournament_id, 2)
      end)

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => master_id})
      assert json_response(conn, 200)["state"] == "IsFinished"
    end

    test "flipban (team) (master is team leader) (until the tournament starts)", %{conn: conn} do
      user = fixture_user()
      attrs = %{
        "capacity" => 4,
        "coin_head_field" => "map選択",
        "coin_tail_field" => "a/d選択",
        "deadline" => "2010-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2010-04-17T14:00:00Z",
        "master_id" => user.id,
        "name" => "some name",
        "join" => "false",
        "url" => "some url",
        "platform" => 1,
        "is_team" => "true",
        "rule" => "flipban",
        "team_size" => 5,
        "type" => 2,
        "enabled_map" => "true",
        "enabled_coin_toss" => "true"
      }

      maps = [
        %{"name" => "map1"},
        %{"name" => "map2"},
        %{"name" => "map3"},
        %{"name" => "map4"},
        %{"name" => "map5"},
        %{"name" => "map6"}
      ]

      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: nil, maps: maps)
      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["data"]["rule"] == "flipban"
      assert json_response(conn, 200)["data"]["is_team"]
      assert json_response(conn, 200)["data"]["enabled_map"]
      assert json_response(conn, 200)["data"]["enabled_coin_toss"]

      master_id = json_response(conn, 200)["data"]["master_id"]
      tournament_id = json_response(conn, 200)["data"]["id"]
      capacity = json_response(conn, 200)["data"]["capacity"]
      team_size = json_response(conn, 200)["data"]["team_size"]

      # NOTE: masterを含める
      10..10 + capacity * team_size - 1 - 1
      |> Enum.to_list()
      |> Enum.map(&fixture_user(num: &1).id)
      |> Enum.concat([master_id])
      |> Enum.reverse()
      |> Enum.chunk_every(team_size)
      |> Enum.map(fn [leader_id | member_id_list] ->
        conn = post(conn, Routes.team_path(conn, :create), %{"tournament_id" => tournament_id, "leader_id" => leader_id, "user_id_list" => member_id_list, "size" => team_size})
        assert json_response(conn, 200)["result"]
        [leader_id | member_id_list]
        |> Enum.each(fn user_id ->
          conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => user_id})
          assert json_response(conn, 200)["state"] == "IsNotStarted"
        end)

        [leader_id | member_id_list]
      end)
      |> Enum.each(fn [leader_id | member_id_list] ->
        member_id_list
        |> Enum.each(fn user_id ->
          user_id
          |> Tournaments.get_invitations()
          |> Enum.each(fn invitation ->
            conn = post(conn, Routes.team_path(conn, :confirm_invitation), %{"invitation_id" => invitation.id})
            assert json_response(conn, 200)["result"]
          end)
        end)
        [leader_id | member_id_list]
      end)

      conn = get(conn, Routes.team_path(conn, :get_confirmed_teams), %{"tournament_id" => tournament_id})

      # NOTE: チームメンバーの人数を確認
      conn
      |> json_response(200)
      |> Map.get("data")
      |> Enum.map(fn team ->
        team["team_member"]
        |> Enum.each(fn member ->
          assert member["is_invitation_confirmed"]
        end)
      end)
      |> length()
      |> then(&(assert &1 == capacity))

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => master_id})
      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["state"] == "IsNotStarted"

      conn = post(conn, Routes.tournament_path(conn, :start), %{"tournament" => %{"master_id" => master_id, "tournament_id" => tournament_id}})
      assert json_response(conn, 200)["result"]

      conn
      |> json_response(200)
      |> Map.get("data")
      |> Map.get("messages")
      |> then(fn messages ->
        assert length(messages) == team_size*capacity
      end)

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => master_id})
      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["state"] == "ShouldFlipCoin"
    end

    defp flip_fight(conn, team1_id, leader1_id, team2_id, leader2_id, tournament_id, match_index) do
      # NOTE: flip前の状態確認
      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => leader1_id})
      json_response(conn, 200)
      assert json_response(conn, 200)["state"] == "ShouldFlipCoin"
      assert json_response(conn, 200)["opponent"]["id"] == team2_id
      assert is_nil(json_response(conn, 200)["score"])
      assert json_response(conn, 200)["rule"] == "flipban"
      conn = get(conn, Routes.tournament_path(conn, :state), %{"tournament_id" => tournament_id, "user_id" => leader1_id})
      assert json_response(conn, 200)["state"] == "ShouldFlipCoin"

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => leader2_id})
      assert json_response(conn, 200)["opponent"]["id"] == team1_id
      assert is_nil(json_response(conn, 200)["score"])
      assert json_response(conn, 200)["state"] == "ShouldFlipCoin"
      assert json_response(conn, 200)["rule"] == "flipban"
      conn = get(conn, Routes.tournament_path(conn, :state), %{"tournament_id" => tournament_id, "user_id" => leader2_id})
      assert json_response(conn, 200)["state"] == "ShouldFlipCoin"

      # NOTE: コインのflip
      conn = post(conn, Routes.tournament_path(conn, :flip_coin), %{"tournament_id" => tournament_id, "user_id" => leader1_id})
      assert json_response(conn, 200)["result"]

      conn
      |> json_response(200)
      |> Map.get("messages")
      |> Enum.map(fn message ->
        assert is_binary(message["state"])
        assert is_integer(message["user_id"])
      end)
      |> Enum.empty?()
      |> refute()

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => leader1_id})
      assert json_response(conn, 200)["state"] == "IsWaitingForCoinFlip"
      is_team1_head = json_response(conn, 200)["is_coin_head"]

      conn = post(conn, Routes.tournament_path(conn, :flip_coin), %{"tournament_id" => tournament_id, "user_id" => leader2_id})
      assert json_response(conn, 200)["result"]

      conn
      |> json_response(200)
      |> Map.get("messages")
      |> Enum.map(fn message ->
        assert is_binary(message["state"])
        assert is_integer(message["user_id"])
      end)
      |> Enum.empty?()
      |> refute()

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => leader2_id})
      is_team2_head = json_response(conn, 200)["is_coin_head"]

      # NOTE: どちらかのみがtrueになるのでXORを使って判定する
      assert is_team1_head <|> is_team2_head
      assert [{leader1_id, team1_id, true}, {leader2_id, team2_id, false}] = Enum.sort_by([{leader1_id, team1_id, is_team1_head}, {leader2_id, team2_id, is_team2_head}], &elem(&1, 2), :desc)

      conn = get(conn, Routes.tournament_path(conn, :maps), %{"tournament_id" => tournament_id})

      conn
      |> json_response(200)
      |> Map.get("data")
      |> Enum.map(&(&1["id"]))
      ~> map_id_list

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => leader1_id})
      assert json_response(conn, 200)["is_coin_head"]
      assert json_response(conn, 200)["state"] == "ShouldBanMap"
      assert json_response(conn, 200)["opponent"]["id"] == team2_id

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => leader2_id})
      refute json_response(conn, 200)["is_coin_head"]
      assert json_response(conn, 200)["state"] == "ShouldObserveBan"
      assert json_response(conn, 200)["opponent"]["id"] == team1_id

      # NOTE: 最初のBAN
      maps = [Enum.at(map_id_list, 0), Enum.at(map_id_list, 1)]
      conn = post(conn, Routes.tournament_path(conn, :ban_maps), %{"user_id" => leader1_id, "tournament_id" => tournament_id, "map_id_list" => maps})
      assert json_response(conn, 200)["result"]

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => leader1_id})
      assert json_response(conn, 200)["is_coin_head"]
      assert json_response(conn, 200)["state"] == "ShouldObserveBan"
      assert json_response(conn, 200)["opponent"]["id"] == team2_id

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => leader2_id})
      refute json_response(conn, 200)["is_coin_head"]
      assert json_response(conn, 200)["state"] == "ShouldBanMap"
      assert json_response(conn, 200)["opponent"]["id"] == team1_id

      # NOTE: 2回目のBAN
      maps = [Enum.at(map_id_list, 2), Enum.at(map_id_list, 3)]
      conn = post(conn, Routes.tournament_path(conn, :ban_maps), %{"user_id" => leader2_id, "tournament_id" => tournament_id, "map_id_list" => maps})
      assert json_response(conn, 200)["result"]

      conn
      |> json_response(200)
      |> Map.get("messages")
      |> Enum.map(fn message ->
        assert is_binary(message["state"])
        assert is_integer(message["user_id"])
      end)
      |> Enum.empty?()
      |> refute()

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => leader1_id})
      assert json_response(conn, 200)["is_coin_head"]
      assert json_response(conn, 200)["state"] == "ShouldChooseMap"
      assert json_response(conn, 200)["opponent"]["id"] == team2_id

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => leader2_id})
      refute json_response(conn, 200)["is_coin_head"]
      assert json_response(conn, 200)["state"] == "ShouldObserveChoose"
      assert json_response(conn, 200)["opponent"]["id"] == team1_id

      # NOTE: マップ選択
      map = Enum.at(map_id_list, 4)
      conn = post(conn, Routes.tournament_path(conn, :choose_map), %{"user_id" => leader1_id, "tournament_id" => tournament_id, "map_id" => map})
      assert json_response(conn, 200)["result"]

      conn
      |> json_response(200)
      |> Map.get("messages")
      |> Enum.map(fn message ->
        assert is_binary(message["state"])
        assert is_integer(message["user_id"])
      end)
      |> Enum.empty?()
      |> refute()

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => leader1_id})
      assert json_response(conn, 200)["is_coin_head"]
      assert json_response(conn, 200)["state"] == "ShouldObserveA/D"
      assert json_response(conn, 200)["opponent"]["id"] == team2_id

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => leader2_id})
      refute json_response(conn, 200)["is_coin_head"]
      assert json_response(conn, 200)["state"] == "ShouldChooseA/D"
      assert json_response(conn, 200)["opponent"]["id"] == team1_id

      # NOTE: A/D選択
      conn = post(conn, Routes.tournament_path(conn, :choose_ad), %{"user_id" => leader2_id, "tournament_id" => tournament_id, "is_attacker_side" => true})
      assert json_response(conn, 200)["result"]

      conn
      |> json_response(200)
      |> Map.get("messages")
      |> Enum.map(fn message ->
        assert is_binary(message["state"])
        assert is_integer(message["user_id"])
      end)
      |> Enum.empty?()
      |> refute()

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => leader1_id})
      assert json_response(conn, 200)["is_coin_head"]
      assert json_response(conn, 200)["state"] == "IsPending"
      assert json_response(conn, 200)["opponent"]["id"] == team2_id
      refute json_response(conn, 200)["is_attacker_side"]

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => leader2_id})
      refute json_response(conn, 200)["is_coin_head"]
      assert json_response(conn, 200)["state"] == "IsPending"
      assert json_response(conn, 200)["opponent"]["id"] == team1_id
      assert json_response(conn, 200)["is_attacker_side"]

      # NOTE: スコア報告
      conn = post(conn, Routes.tournament_path(conn, :claim_score), %{"tournament_id" => tournament_id, "user_id" => leader1_id, "score" => 13, "match_index" => match_index})
      assert json_response(conn, 200)["validated"]
      refute json_response(conn, 200)["completed"]
      refute json_response(conn, 200)["is_finished"]

      # NOTE: 勝敗報告がお互いに完了するまではstateは動かないので、messagesもempty
      conn
      |> json_response(200)
      |> Map.get("messages")
      |> Enum.empty?()
      |> assert()

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => leader1_id})
      assert json_response(conn, 200)["state"] == "IsWaitingForScoreInput"
      assert json_response(conn, 200)["score"] == 13

      conn = post(conn, Routes.tournament_path(conn, :claim_score), %{"tournament_id" => tournament_id, "user_id" => leader2_id, "score" => 8, "match_index" => match_index})
      assert json_response(conn, 200)["validated"]
      assert json_response(conn, 200)["completed"]
      assert json_response(conn, 200)["is_finished"] or match_index != 2

      conn
      |> json_response(200)
      |> Map.get("messages")
      |> Enum.map(fn message ->
        assert is_binary(message["state"])
        assert is_integer(message["user_id"])
      end)
      |> Enum.empty?()
      |> refute()

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => leader1_id})
      state = json_response(conn, 200)["state"]
      assert state == "IsAlone" or state == "ShouldFlipCoin" or state == "IsFinished"
      refute json_response(conn, 200)["score"]
      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => leader2_id})
      state = json_response(conn, 200)["state"]
      assert state == "IsLoser" or state == "IsFinished"
      refute json_response(conn, 200)["score"]
    end

    test "flipban_roundrobin (team)", %{conn: conn} do
      user = fixture_user()
      attrs = %{
        "capacity" => 4,
        "coin_head_field" => "マップ選択",
        "coin_tail_field" => "a/d選択",
        "deadline" => "2010-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2010-04-17T14:00:00Z",
        "master_id" => user.id,
        "name" => "some name",
        "join" => "false",
        "url" => "some url",
        "platform" => 1,
        "is_team" => "true",
        "rule" => "flipban_roundrobin",
        "team_size" => 5,
        "type" => 2,
        # XXX: ここあとでvalidateに追加しないと head_fieldとかもいるかも
        "enabled_map" => "true",
        "enabled_coin_toss" => "true"
      }

      maps = [
        %{"name" => "map1"},
        %{"name" => "map2"},
        %{"name" => "map3"},
        %{"name" => "map4"},
        %{"name" => "map5"},
        %{"name" => "map6"}
      ]

      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: nil, maps: maps)
      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["data"]["rule"] == "flipban_roundrobin"
      assert json_response(conn, 200)["data"]["is_team"]
      assert json_response(conn, 200)["data"]["enabled_map"]
      assert json_response(conn, 200)["data"]["enabled_coin_toss"]

      master_id = json_response(conn, 200)["data"]["master_id"]
      tournament_id = json_response(conn, 200)["data"]["id"]
      capacity = json_response(conn, 200)["data"]["capacity"]
      team_size = json_response(conn, 200)["data"]["team_size"]

      conn = get(conn, Routes.tournament_path(conn, :get_match_information), %{"tournament_id" => tournament_id, "user_id" => master_id})
      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["state"] === "IsNotStarted"


      # TODO: flipban_roundrobinの動作確認用テスト記述
    end
  end

  describe "is user win" do
    test "works", %{conn: conn} do
      tournament = fixture_tournament()
      create_entrants(8, tournament.id)

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

      conn = get(conn, Routes.tournament_path(conn, :get_match_list), %{"tournament_id" => tournament.id})
      match_list = json_response(conn, 200)["match_list"]

      match_list
      |> List.flatten()
      |> Enum.chunk_every(2)
      |> hd()
      ~> [user1_id, user2_id]

      conn = post(conn, Routes.tournament_path(conn, :start_match), %{"user_id" => user2_id, "tournament_id" => tournament.id})
      assert json_response(conn, 200)["result"]
      conn = post(conn, Routes.tournament_path(conn, :start_match), %{"user_id" => user1_id, "tournament_id" => tournament.id})
      assert json_response(conn, 200)["result"]

      conn =
        post(conn, Routes.tournament_path(conn, :claim_win),
          opponent_id: user2_id,
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
          user_id: user2_id,
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

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

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

      conn
      |> json_response(200)
      |> Map.get("score")
      |> is_nil()
      |> assert()
    end
  end

  describe "force to defeat (basic)" do
    setup [:create_tournament]

    test "works with size 4 tournament", %{conn: conn, tournament: tournament} do
      entrants = create_entrants(4, tournament.id)
      entrant1 = hd(entrants)

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

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

      conn
      |> json_response(200)
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
      |> then(fn len ->
        assert len == length(entrants)
      end)
    end
  end

  describe "force to defeat (flipban)" do
    test "works with flipban", %{conn: conn} do
      user = fixture_user()
      attrs = %{
        "capacity" => 4,
        "coin_head_field" => "マップ選択",
        "coin_tail_field" => "a/d選択",
        "deadline" => "2010-04-17T14:00:00Z",
        "description" => "some description",
        "event_date" => "2010-04-17T14:00:00Z",
        "master_id" => user.id,
        "name" => "some name",
        "join" => "false",
        "url" => "some url",
        "platform" => 1,
        "is_team" => "true",
        "rule" => "flipban",
        "team_size" => 5,
        "type" => 2,
        # XXX: ここあとでvalidateに追加しないと head_fieldとかもいるかも
        "enabled_map" => "true",
        "enabled_coin_toss" => "true"
      }

      maps = [
        %{"name" => "map1"},
        %{"name" => "map2"},
        %{"name" => "map3"},
        %{"name" => "map4"},
        %{"name" => "map5"},
        %{"name" => "map6"}
      ]

      conn = post(conn, Routes.tournament_path(conn, :create), tournament: attrs, file: nil, maps: maps)

      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["data"]["rule"] == "flipban"
      assert json_response(conn, 200)["data"]["is_team"]

      master_id = json_response(conn, 200)["data"]["master_id"]
      tournament_id = json_response(conn, 200)["data"]["id"]

      fill_with_team(tournament_id)
      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => master_id, "tournament_id" => tournament_id})
      assert json_response(conn, 200)["result"]

      conn = get(conn, Routes.tournament_path(conn, :get_match_list), %{"tournament_id" => tournament_id})
      assert json_response(conn, 200)["result"]
      match_list = json_response(conn, 200)["match_list"]

      match_list
      |> List.flatten()
      |> hd()
      ~> team_id
      |> Tournaments.get_leader()
      |> Map.get(:user_id)

      conn =
        post(conn, Routes.tournament_path(conn, :force_to_defeat),
          tournament_id: tournament_id,
          target_team_id: team_id
        )

      json_response(conn, 200)

      conn =
        get(conn, Routes.tournament_path(conn, :chunk_bracket_data_for_best_of_format), %{
          "tournament_id" => tournament_id
        })

      assert json_response(conn, 200)["result"]

      conn
      |> json_response(200)
      |> Map.get("data")
      |> Enum.any?(fn bracket ->
        bracket["is_loser"]
      end)
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

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

      conn = get(conn, Routes.tournament_path(conn, :get_match_members), tournament_id: tournament.id)

      response = json_response(conn, 200)

      response
      |> Map.get("data")
      |> Map.get("assistants")
      |> Enum.empty?()
      |> assert()

      response
      |> Map.get("data")
      |> Map.get("entrants")
      |> length()
      |> then(fn len ->
        assert len == 8
      end)

      response
      |> Map.get("data")
      |> Map.get("master")
      |> Map.get("data")
      |> then(fn user ->
        assert user["id"] == tournament.master_id
      end)
    end

    test "works (team)", %{conn: conn} do
      [is_team: true, capacity: 4, type: 2, num: 50000]
      |> fixture_tournament()
      ~> tournament
      |> Map.get(:id)
      |> fill_with_team()

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

      conn = get(conn, Routes.tournament_path(conn, :get_match_members), tournament_id: tournament.id)

      response = json_response(conn, 200)
      assert response["result"]

      response
      |> Map.get("data")
      |> Map.get("master")
      |> Map.get("data")
      |> Map.get("id")
      |> Kernel.==(tournament.master_id)
      |> assert()

      response
      |> Map.get("data")
      |> Map.get("assistants")
      |> Enum.empty?()
      |> assert()

      response
      |> Map.get("data")
      |> Map.get("entrants")
      |> Enum.empty?()
      |> assert()

      response
      |> Map.get("data")
      |> Map.get("teams")
      |> Enum.map(fn team ->
        assert team["tournament_id"] == tournament.id
        assert Map.has_key?(team, "id")
      end)
      |> length()
      |> Kernel.==(4)
      |> assert()
    end

    test "works (checks log as well)", %{conn: conn} do
      tournament = fixture_tournament(capacity: 2, num: 2, type: 2)
      [entrant1, entrant2] = fill_with_entrant(tournament.id)

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

      conn = get(conn, Routes.tournament_path(conn, :get_match_members), tournament_id: tournament.id)

      conn
      |> json_response(200)
      |> Map.get("data")
      |> Map.get("entrants")
      |> Enum.map(fn entrant ->
        assert is_map(entrant)
      end)
      |> length()
      |> Kernel.==(2)
      |> assert()

      conn = post(conn, Routes.tournament_path(conn, :start_match),
          user_id: entrant1.user_id,
          tournament_id: tournament.id
        )

      conn = post(conn, Routes.tournament_path(conn, :start_match),
          user_id: entrant2.user_id,
          tournament_id: tournament.id
        )

      conn =
        post(conn, Routes.tournament_path(conn, :claim_score),
          opponent_id: entrant1.user_id,
          user_id: entrant2.user_id,
          tournament_id: tournament.id,
          score: 1,
          match_index: 0
        )

      conn =
        post(conn, Routes.tournament_path(conn, :claim_score),
          opponent_id: entrant2.user_id,
          user_id: entrant1.user_id,
          tournament_id: tournament.id,
          score: 2,
          match_index: 0
        )

      conn = get(conn, Routes.tournament_path(conn, :show), tournament_id: tournament.id)

      conn
      |> json_response(200)
      |> Map.get("is_log")
      |> assert()

      conn = get(conn, Routes.tournament_path(conn, :get_match_members), tournament_id: tournament.id)

      conn
      |> json_response(200)
      |> Map.get("result")
      |> assert()
    end
  end

  # TODO: redisの確認を入れたい
  describe "test duplicate claim members" do
    setup [:create_tournament]

    test "get duplicate claim members", %{conn: conn, tournament: tournament} do
      entrants = create_entrants(17, tournament.id)
      player = hd(entrants)

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

      conn =
        get(conn, Routes.tournament_path(conn, :get_opponent), %{
          "tournament_id" => tournament.id,
          "user_id" => player.user_id
        })

      response = json_response(conn, 200)

      cond do
        !is_nil(response["opponent"])                              -> true
        is_nil(response["opponent"]) and !is_nil(response["wait"]) -> false
        :else                                                      -> assert false, "it must not be true"
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
        |> Progress.get_duplicate_users()
        |> Kernel.==([opponent["id"], player.user_id])
        |> Kernel.||(
          tournament.id
          |> Progress.get_duplicate_users()
          |> Kernel.==([player.user_id, opponent["id"]])
        )
        |> assert()

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
          |> assert()
        end)
      else
        Logger.info("opponent is nil in 'test duplicate claim members'")
      end
    end
  end

  describe "get game masters" do
    setup [:create_tournament]

    test "get game masters", %{conn: conn, tournament: tournament} do
      conn = get(conn, Routes.tournament_path(conn, :get_game_masters), tournament_id: tournament.id)

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

  describe "data for ios" do
    test "works just like get_match_information", %{conn: conn} do
      tournament = fixture_tournament(capacity: 4)
      entrants = fill_with_entrant(tournament.id)

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

      tournament.id
      |> Progress.get_match_list()
      |> List.flatten()
      |> length()
      |> Kernel.==(4)
      |> assert()

      me = hd(entrants).user_id

      conn =
        get(conn, Routes.tournament_path(conn, :get_match_information),
          tournament_id: tournament.id,
          user_id: me
        )

      match_info = json_response(conn, 200)

      conn =
        get(conn, Routes.tournament_path(conn, :get_started_match_information),
          user_id: me
        )

      get_started_match_information = json_response(conn, 200)

      assert match_info == get_started_match_information
    end
  end

  describe "get match information" do
    test "individual tournament works", %{conn: conn} do
      tournament = fixture_tournament(capacity: 4)
      entrants = fill_with_entrant(tournament.id)

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

      json_response(conn, 200)

      tournament.id
      |> Progress.get_match_list()
      |> List.flatten()
      |> length()
      |> Kernel.==(4)
      |> assert()

      me = hd(entrants).user_id

      conn =
        get(conn, Routes.tournament_path(conn, :get_match_information),
          tournament_id: tournament.id,
          user_id: me
        )

      match_info = json_response(conn, 200)

      assert is_nil(match_info["is_leader"])
      assert match_info["rank"] == 4
      assert is_nil(match_info["score"])
      assert match_info["state"] == "ShouldStartMatch"
      refute is_nil(match_info["opponent"]["id"])
      assert Map.has_key?(match_info["opponent"], "icon_path")
      refute is_nil(match_info["opponent"]["name"])

      conn =
        post(conn, Routes.tournament_path(conn, :start_match),
          user_id: me,
          tournament_id: tournament.id
        )

      conn =
        get(conn, Routes.tournament_path(conn, :get_match_information),
          tournament_id: tournament.id,
          user_id: me
        )

      match_info = json_response(conn, 200)

      assert is_nil(match_info["is_leader"])
      assert match_info["rank"] == 4
      assert is_nil(match_info["score"])
      assert match_info["state"] == "IsWaitingForStartMatch"
      refute is_nil(match_info["opponent"]["id"])
      assert Map.has_key?(match_info["opponent"], "icon_path")
      refute is_nil(match_info["opponent"]["name"])

      conn =
        get(conn, Routes.tournament_path(conn, :get_opponent),
          tournament_id: tournament.id,
          user_id: me
        )

      opponent_id = json_response(conn, 200)["opponent"]["id"]

      conn =
        post(conn, Routes.tournament_path(conn, :start_match),
          user_id: opponent_id,
          tournament_id: tournament.id
        )

      conn =
        get(conn, Routes.tournament_path(conn, :get_match_information),
          tournament_id: tournament.id,
          user_id: opponent_id
        )

      match_info = json_response(conn, 200)
      assert match_info["state"] == "IsPending"

      my_score = 100
      opponent_score = 5

      conn =
        post(conn, Routes.tournament_path(conn, :claim_score),
          tournament_id: tournament.id,
          user_id: me,
          opponent_id: opponent_id,
          score: my_score,
          match_index: 1
        )

      conn =
        get(conn, Routes.tournament_path(conn, :get_match_information),
          tournament_id: tournament.id,
          user_id: me
        )

      match_info = json_response(conn, 200)
      assert match_info["opponent"]["id"] == opponent_id
      assert match_info["score"] == my_score
      assert match_info["state"] == "IsWaitingForScoreInput"

      conn =
        post(conn, Routes.tournament_path(conn, :claim_score),
          tournament_id: tournament.id,
          user_id: opponent_id,
          opponent_id: me,
          score: opponent_score,
          match_index: 1
        )

      assert json_response(conn, 200)["completed"]

      conn =
        get(conn, Routes.tournament_path(conn, :get_match_information),
          tournament_id: tournament.id,
          user_id: me
        )

      match_info = json_response(conn, 200)

      assert match_info["state"] == "IsAlone"
      assert match_info["rank"] == 2
      assert is_nil(match_info["score"])
      assert is_nil(match_info["is_leader"])
    end

    test "team tournament works", %{conn: conn} do
      tournament = fixture_tournament(capacity: 4, is_team: true, type: 2)
      teams = fill_with_team(tournament.id)

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

      assert json_response(conn, 200)["result"]

      tournament.id
      |> Progress.get_match_list()
      |> List.flatten()
      |> length()
      |> Kernel.==(4)
      |> assert()

      teams
      |> hd()
      |> Map.get(:id)
      ~> my_team
      |> Tournaments.get_leader()
      |> Map.get(:user)
      ~> me

      conn =
        get(conn, Routes.tournament_path(conn, :get_opponent),
          tournament_id: tournament.id,
          team_id: my_team
        )

      json_response(conn, 200)
      |> Map.get("opponent")
      |> Map.get("id")
      |> Tournaments.get_team()
      |> Map.get(:id)
      |> Tournaments.get_leader()
      |> Map.get(:user)
      ~> opponent

      conn =
        get(conn, Routes.tournament_path(conn, :get_match_information),
          tournament_id: tournament.id,
          user_id: me.id
        )

      match_info = json_response(conn, 200)

      assert match_info["is_leader"]
      assert match_info["rank"] == 4
      assert is_nil(match_info["score"])
      assert match_info["state"] == "ShouldStartMatch"
      refute is_nil(match_info["opponent"]["id"])
      assert match_info["opponent"]["name"] == "#{opponent.name}のチーム"
      assert Map.has_key?(match_info["opponent"], "icon_path")

      conn =
        post(conn, Routes.tournament_path(conn, :start_match),
          user_id: me.id,
          tournament_id: tournament.id
        )

      assert json_response(conn, 200)["result"]

      conn =
        get(conn, Routes.tournament_path(conn, :get_match_information),
          tournament_id: tournament.id,
          user_id: me.id
        )

      match_info = json_response(conn, 200)

      assert match_info["is_leader"]
      assert match_info["rank"] == 4
      assert is_nil(match_info["score"])
      assert match_info["state"] == "IsWaitingForStartMatch"

      tournament.id
      |> Tournaments.get_teammates(me.id)
      |> Enum.filter(fn member ->
        !member.is_leader
      end)
      |> hd()
      |> Map.get(:user)
      ~> mate

      conn =
        get(conn, Routes.tournament_path(conn, :get_match_information),
          tournament_id: tournament.id,
          user_id: mate.id
        )

      match_info = json_response(conn, 200)

      refute match_info["is_leader"]
      assert match_info["rank"] == 4
      assert is_nil(match_info["score"])
      assert match_info["state"] == "IsMember"

      conn =
        get(conn, Routes.tournament_path(conn, :get_opponent),
          tournament_id: tournament.id,
          team_id: my_team
        )

      assert json_response(conn, 200)["result"]
      opponent_id = json_response(conn, 200)["opponent"]["id"]

      opponent_id
      |> Tournaments.get_leader()
      |> Map.get(:user)
      ~> opponent

      conn =
        post(conn, Routes.tournament_path(conn, :start_match),
          user_id: opponent.id,
          tournament_id: tournament.id
        )

      opponent_id
      |> Tournaments.get_team_members_by_team_id()
      |> Enum.filter(fn member ->
        !member.is_leader
      end)
      |> hd()
      |> Map.get(:user_id)
      ~> opponent_member

      conn =
        get(conn, Routes.tournament_path(conn, :get_match_information),
          tournament_id: tournament.id,
          user_id: opponent_member
        )

      match_info = json_response(conn, 200)
      refute is_nil(match_info["is_leader"])

      if match_info["is_leader"] do
        assert match_info["state"] == "IsPending"
      else
        assert match_info["state"] == "IsMember"
      end

      assert match_info["rank"] == 4

      my_score = 100
      opponent_score = 5

      conn =
        post(conn, Routes.tournament_path(conn, :claim_score),
          tournament_id: tournament.id,
          user_id: me.id,
          opponent_id: opponent.id,
          score: my_score,
          match_index: 1
        )

      assert json_response(conn, 200)["validated"]
      refute json_response(conn, 200)["completed"]

      conn =
        get(conn, Routes.tournament_path(conn, :get_match_information),
          tournament_id: tournament.id,
          user_id: mate.id
        )

      match_info = json_response(conn, 200)

      refute match_info["is_leader"]
      assert match_info["rank"] == 4
      assert is_nil(match_info["score"])
      assert match_info["state"] == "IsMember"

      conn =
        post(conn, Routes.tournament_path(conn, :claim_score),
          tournament_id: tournament.id,
          user_id: opponent.id,
          opponent_id: me.id,
          score: opponent_score,
          match_index: 1
        )

      assert json_response(conn, 200)["validated"]
      assert json_response(conn, 200)["completed"]

      conn =
        get(conn, Routes.tournament_path(conn, :get_match_information),
          tournament_id: tournament.id,
          user_id: mate.id
        )

      match_info = json_response(conn, 200)

      assert is_nil(match_info["opponent"])
      assert match_info["state"] == "IsMember"
      assert match_info["rank"] == 2
      assert is_nil(match_info["score"])
      refute match_info["is_leader"]

      conn =
        get(conn, Routes.tournament_path(conn, :get_match_information),
          tournament_id: tournament.id,
          user_id: opponent_member
        )

      match_info = json_response(conn, 200)
      refute is_nil(match_info["is_leader"])
      assert match_info["state"] == "IsMember"
      assert match_info["rank"] == 4
    end

    test "finish (individual)", %{conn: conn} do
      capacity = 2

      tournament = fixture_tournament(capacity: capacity)
      entrants = fill_with_entrant(tournament.id)

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

      tournament.id
      |> Progress.get_match_list()
      |> List.flatten()
      |> length()
      |> Kernel.==(capacity)
      |> assert()

      me = hd(entrants).user_id

      conn =
        get(conn, Routes.tournament_path(conn, :get_match_information),
          tournament_id: tournament.id,
          user_id: me
        )

      match_info = json_response(conn, 200)

      assert is_nil(match_info["is_leader"])
      assert match_info["rank"] == capacity
      assert is_nil(match_info["score"])
      assert match_info["state"] == "ShouldStartMatch"
      refute is_nil(match_info["opponent"]["id"])
      assert Map.has_key?(match_info["opponent"], "icon_path")
      refute is_nil(match_info["opponent"]["name"])

      conn =
        post(conn, Routes.tournament_path(conn, :start_match),
          user_id: me,
          tournament_id: tournament.id
        )

      conn =
        get(conn, Routes.tournament_path(conn, :get_opponent),
          tournament_id: tournament.id,
          user_id: me
        )

      opponent_id = json_response(conn, 200)["opponent"]["id"]

      conn =
        post(conn, Routes.tournament_path(conn, :start_match),
          user_id: opponent_id,
          tournament_id: tournament.id
        )

      conn =
        get(conn, Routes.tournament_path(conn, :get_match_information),
          tournament_id: tournament.id,
          user_id: opponent_id
        )

      match_info = json_response(conn, 200)
      assert match_info["state"] == "IsPending"

      my_score = 100
      opponent_score = 5

      conn =
        post(conn, Routes.tournament_path(conn, :claim_score),
          tournament_id: tournament.id,
          user_id: me,
          opponent_id: opponent_id,
          score: my_score,
          match_index: 1
        )

      conn =
        post(conn, Routes.tournament_path(conn, :claim_score),
          tournament_id: tournament.id,
          user_id: opponent_id,
          opponent_id: me,
          score: opponent_score,
          match_index: 1
        )

      conn =
        get(conn, Routes.tournament_path(conn, :get_match_information),
          tournament_id: tournament.id,
          user_id: me
        )

      match_info = json_response(conn, 200)

      assert is_nil(match_info["opponent"])
      assert match_info["rank"] == capacity / 2
    end

    test "finish (team)", %{conn: conn} do
      capacity = 2
      tournament = fixture_tournament(is_team: true, capacity: capacity, type: 2)
      teams = fill_with_team(tournament.id)

      teams
      |> hd()
      |> Map.get(:id)
      |> Tournaments.get_leader()
      |> Map.get(:user)
      |> Map.get(:id)
      ~> my_id

      teams
      |> tl()
      |> hd()
      |> Map.get(:id)
      ~> opponent_team_id
      |> Tournaments.get_leader()
      |> Map.get(:user)
      |> Map.get(:id)
      ~> opponent_id

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

      conn =
        get(conn, Routes.tournament_path(conn, :get_match_information),
          tournament_id: tournament.id,
          user_id: my_id
        )

      match_info = json_response(conn, 200)

      assert match_info["is_leader"]
      assert match_info["rank"] == capacity
      assert is_nil(match_info["score"])
      assert match_info["is_team"]
      assert match_info["opponent"]["id"] == opponent_team_id
      refute is_nil(match_info["opponent"]["name"])
      assert match_info["state"] == "ShouldStartMatch"

      conn =
        post(conn, Routes.tournament_path(conn, :start_match),
          user_id: my_id,
          tournament_id: tournament.id
        )

      conn =
        post(conn, Routes.tournament_path(conn, :start_match),
          user_id: opponent_id,
          tournament_id: tournament.id
        )

      my_score = 100
      opponent_score = 5

      conn =
        post(conn, Routes.tournament_path(conn, :claim_score),
          tournament_id: tournament.id,
          user_id: my_id,
          opponent_id: opponent_id,
          score: my_score,
          match_index: 1
        )

      conn =
        get(conn, Routes.tournament_path(conn, :get_match_information),
          tournament_id: tournament.id,
          user_id: my_id
        )

      match_info = json_response(conn, 200)

      assert match_info["is_leader"]
      assert match_info["rank"] == capacity
      assert match_info["score"] == my_score
      assert match_info["is_team"]
      assert match_info["opponent"]["id"] == opponent_team_id
      refute is_nil(match_info["opponent"]["name"])
      assert match_info["state"] === "IsWaitingForScoreInput"

      # NOTE: 通知が存在するか確認
      tournament.id
      |> Notif.get_notifications_relevant_for_tournament()
      |> length()
      |> Kernel.==(0)
      |> refute()

      conn =
        post(conn, Routes.tournament_path(conn, :claim_score),
          tournament_id: tournament.id,
          user_id: opponent_id,
          opponent_id: my_id,
          score: opponent_score,
          match_index: 1
        )

      conn =
        get(conn, Routes.tournament_path(conn, :get_match_information),
          tournament_id: tournament.id,
          user_id: my_id
        )

      match_info = json_response(conn, 200)
      assert match_info["state"] === "IsFinished"
      assert match_info["rank"] == capacity / 2
      assert match_info["is_leader"]

      # NOTE: 通知が消えてるか確認
      tournament.id
      |> Notif.get_notifications_relevant_for_tournament()
      |> length()
      |> Kernel.==(0)
      |> assert()
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

      #conn = post(conn, Routes.tournament_path(conn, :delete_loser), tournament: %{tournament_id: tournament["id"], loser_list: [user1_id]})

      conn =
        get(conn, Routes.tournament_path(conn, :tournament_topics),
          tournament_id: tournament["id"],
          user_id: tournament["master_id"]
        )

      assert json_response(conn, 200)["result"]

      conn
      |> json_response(200)
      |> Map.get("data")
      |> Enum.empty?()
      |> assert()

      conn = get(conn, Routes.tournament_path(conn, :show), tournament_id: tournament["id"])

      conn
      |> json_response(200)
      |> then(fn t ->
        assert t["is_log"]
        assert t["result"]
        t
      end)
      |> Map.get("data")
      |> then(fn t ->
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
      end)

      conn =
        get(conn, Routes.tournament_path(conn, :tournament_topics),
          tournament_id: tournament["id"],
          user_id: tournament["master_id"]
        )

      assert json_response(conn, 200)["result"]

      conn
      |> json_response(200)
      |> Map.get("data")
      |> Enum.map(fn topic_log ->
        assert topic_log["tournament_id"] == tournament["id"]
      end)
      |> length()
      |> then(fn len ->
        assert len == 0
      end)

      tournament["id"]
      |> Progress.get_match_list()
      |> is_nil()
      |> assert()

      tournament["id"]
      |> Progress.get_match_list_with_fight_result()
      |> is_nil()
      |> assert()

      tournament["id"]
      |> Progress.get_match_list_with_fight_result_including_log()
      |> then(fn list ->
        list
        |> length()
        |> Kernel.==(2)
        |> assert()
      end)

      tournament["id"]
      |> Progress.get_match_pending_list_of_tournament()
      |> Enum.empty?()
      |> assert()
    end
  end

  describe "brackets with fight result" do
    test "works", %{conn: conn} do
      tournament = fixture_tournament()
      entrants = create_entrants(8, tournament.id)

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

      user_id_list = Enum.map(entrants, fn entrant -> entrant.user_id end)

      conn = get(conn, Routes.tournament_path(conn, :brackets_with_fight_result), tournament_id: tournament.id)

      assert json_response(conn, 200)["count"] == length(entrants)

      conn
      |> json_response(200)
      |> Map.get("data")
      |> List.flatten()
      |> Enum.map(fn bracket ->
        refute bracket["is_loser"]
        assert bracket["user_id"] in user_id_list
      end)
      |> length()
      |> then(fn len ->
        assert len == 8
      end)

      conn = get(conn, Routes.tournament_path(conn, :get_match_list), %{"tournament_id" => tournament.id})
      match_list = json_response(conn, 200)["match_list"]

      match_list
      |> List.flatten()
      |> Enum.chunk_every(2)
      |> hd()
      ~> [user1_id, user2_id]

      conn = post(conn, Routes.tournament_path(conn, :start_match), %{"user_id" => user2_id, "tournament_id" => tournament.id})
      assert json_response(conn, 200)["result"]
      conn = post(conn, Routes.tournament_path(conn, :start_match), %{"user_id" => user1_id, "tournament_id" => tournament.id})
      assert json_response(conn, 200)["result"]

      conn =
        post(conn, Routes.tournament_path(conn, :claim_win),
          opponent_id: user2_id,
          user_id: user1_id,
          tournament_id: tournament.id
        )

      conn =
        post(conn, Routes.tournament_path(conn, :claim_lose),
          opponent_id: user1_id,
          user_id: user2_id,
          tournament_id: tournament.id
        )

      #conn = post(conn, Routes.tournament_path(conn, :delete_loser), tournament: %{"tournament_id" => tournament.id, "loser_list" => [opponent1_id]})

      conn = get(conn, Routes.tournament_path(conn, :brackets_with_fight_result), tournament_id: tournament.id)

      assert json_response(conn, 200)["count"] == length(entrants)

      conn
      |> json_response(200)
      |> Map.get("data")
      |> List.flatten()
      |> Enum.map(fn bracket ->
        if bracket["user_id"] == user2_id do
          assert bracket["is_loser"]
        else
          refute bracket["is_loser"]
        end

        assert bracket["user_id"] in user_id_list
      end)
      |> length()
      |> then(fn len ->
        assert len == 8
      end)
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

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

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

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

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

    test "works (team)", %{conn: conn} do
      tournament = fixture_tournament(is_team: true, capacity: 4, type: 2)
      fill_with_team(tournament.id)

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{master_id: tournament.master_id, tournament_id: tournament.id})

      json_response(conn, 200)

      tournament.id
      |> Progress.get_match_list_with_fight_result()
      |> List.flatten()
      |> length()
      |> Kernel.==(4)
      |> assert()

      conn = get(conn, Routes.tournament_path(conn, :chunk_bracket_data_for_best_of_format), tournament_id: tournament.id)

      assert json_response(conn, 200)["result"]

      json_response(conn, 200)
      |> Map.get("data")
      |> Enum.map(fn bracket ->
        assert bracket["game_scores"] == []
        refute bracket["is_loser"]
        assert Map.has_key?(bracket, "team_id")
        refute Map.has_key?(bracket, "user_id")
      end)
      |> length()
      |> Kernel.==(4)
      |> assert()
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

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

      conn =
        get(conn, Routes.tournament_path(conn, :get_opponent), %{
          "tournament_id" => tournament.id,
          "user_id" => entrant1.user_id
        })

      entrant1.user_id
      |> Progress.get_match_pending_list(tournament.id)
      |> is_nil()
      |> assert()

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
      |> Progress.get_match_pending_list(tournament.id)
      |> then(fn state ->
        assert state == "IsWaitingForStart"
      end)

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
        |> Progress.get_match_list()

      match_list_with_fight_result =
        tournament.id
        |> Progress.get_match_list_with_fight_result()

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

      conn = post(conn, Routes.tournament_path(conn, :start), tournament: %{"master_id" => tournament.master_id, "tournament_id" => tournament.id})

      entrant1.user_id
      |> Progress.get_match_pending_list(tournament.id)
      |> is_nil()
      |> assert()

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
      |> Progress.get_match_pending_list(tournament.id)
      |> then(fn state ->
        assert state == "IsWaitingForStart"
      end)

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

      conn
      |> json_response(200)
      |> then(fn t ->
        assert t["is_log"]
        assert t["result"]
        t
      end)
      |> Map.get("data")
      |> then(fn t ->
        assert t["tournament_id"] == tournament.id
        assert t["capacity"] == tournament.capacity
        assert t["description"] == tournament.description
        assert t["game_id"] == tournament.game_id
        assert t["game_name"] == tournament.game_name
        assert t["winner_id"] == entrant1.user_id
        assert t["master_id"] == tournament.master_id
        assert t["name"] == tournament.name
        assert t["url"] == tournament.url
      end)
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

  defp create_tournament(_) do
    tournament = fixture_tournament(capacity: 20)
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

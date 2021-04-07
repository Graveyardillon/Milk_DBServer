defmodule MilkWeb.TournamentControllerTest do
  use MilkWeb.ConnCase

  alias Milk.{Accounts, Tournaments}

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
  @invalid_attrs %{"capacity" => nil, "deadline" => nil, "description" => nil, "event_date" => nil, "game_id" => nil, "master_id" => nil, "name" => nil, "type" => nil, "url" => nil, }

  @create_user_attrs %{"icon_path" => "some icon_path", "language" => "some language", "name" => "some name", "notification_number" => 42, "point" => 42, "email" => "some2@email.com", "logout_fl" => true, "password" => "S1ome password"}

  def fixture(:tournament) do
    {:ok, user} =
      %{"name" => "name", "email" => "e@mail.com", "password" => "Password123"}
      |> Accounts.create_user()
    {:ok, tournament} = Tournaments.create_tournament(%{@create_attrs|"master_id" => user.id})
    tournament
  end

  def fixture(:user) do
    {:ok, _user} = Accounts.create_user(@create_user_attrs)
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
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
    end

    test "cannot get a tournament which does not exist", %{conn: conn, tournament: _tournament} do
      conn = get(conn, Routes.tournament_path(conn, :show), %{"tournament_id" => -1})
      refute json_response(conn, 200)["result"]
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

  describe "create tournament" do
    test "renders tournament when data is valid", %{conn: conn} do
      {:ok, user} = fixture(:user)
      attrs = Map.put(@create_attrs, "master_id", user.id)
      conn = post(conn, Routes.tournament_path(conn, :create), %{tournament: attrs, file: ""})
      assert %{"id" => id} = json_response(conn, 200)["data"]

      conn = post(conn, Routes.tournament_path(conn, :show, %{"tournament_id" => id}))

      assert _tournament = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.tournament_path(conn, :create), tournament: @invalid_attrs, file: "")
      assert json_response(conn, 200)["error"] == "join parameter is nil"
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

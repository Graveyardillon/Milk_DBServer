defmodule MilkWeb.TournamentControllerTest do
  use MilkWeb.ConnCase

  alias Milk.Accounts
  alias Milk.Tournaments
  alias Milk.Tournaments.Tournament

  @create_attrs %{
    capacity: 42,
    deadline: "2050-04-17T14:00:00Z",
    description: "some description",
    event_date: "2050-04-17T14:00:00Z",
    name: "some name",
    type: 42,
    url: "some url"
  }
  @update_attrs %{
    capacity: 43,
    deadline: "2011-05-18T15:01:01Z",
    description: "some updated description",
    event_date: "2011-05-18T15:01:01Z",
    master_id: 1,
    name: "some updated name",
    type: 43,
    url: "some updated url"
  }
  @invalid_attrs %{capacity: nil, deadline: nil, description: nil, event_date: nil, game_id: nil, master_id: nil, name: nil, type: nil, url: nil}

  @create_user_attrs %{"icon_path" => "some icon_path", "language" => "some language", "name" => "some name", "notification_number" => 42, "point" => 42, "email" => "some2@email.com", "logout_fl" => true, "password" => "S1ome password"}

  def fixture(:tournament) do
    {:ok, tournament} = Tournaments.create_tournament(@create_attrs)
    tournament
  end

  def fixture(:user) do
    {:ok, user} = Accounts.create_user(@create_user_attrs)
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create tournament" do
    test "renders tournament when data is valid", %{conn: conn} do
      {:ok, user} = fixture(:user)
      attrs = Map.put(@create_attrs, :master_id, user.id)
      conn = post(conn, Routes.tournament_path(conn, :create), %{tournament: attrs, file: ""})
      IO.inspect(json_response(conn, 200), label: :ct)
      assert %{"id" => id} = json_response(conn, 200)["data"]
      #IO.inspect(Tournaments.list_tournament())

      conn = post(conn, Routes.tournament_path(conn, :show, %{"tournament_id" => id}))

      assert _tournament = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.tournament_path(conn, :create), tournament: @invalid_attrs, image: "")
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update tournament" do
    setup [:create_tournament]

    test "renders tournament when data is valid", %{conn: conn, tournament: %Tournament{id: id} = tournament} do
      conn = put(conn, Routes.tournament_path(conn, :update, tournament), tournament: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.tournament_path(conn, :show, id))

      assert %{
        "id" => id,
        "capacity" => 43,
        "deadline" => "2011-05-18T15:01:01Z",
        "description" => "some updated description",
        "event_date" => "2011-05-18T15:01:01Z",
        "game_id" => 43,
        "master_id" => 43,
        "name" => "some updated name",
        "type" => 43,
        "url" => "some updated url"
      } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, tournament: tournament} do
      conn = put(conn, Routes.tournament_path(conn, :update, tournament), tournament: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete tournament" do
    setup [:create_tournament]

    test "deletes chosen tournament", %{conn: conn, tournament: tournament} do
      conn = delete(conn, Routes.tournament_path(conn, :delete, tournament))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.tournament_path(conn, :show, tournament))
      end
    end
  end

  defp create_tournament(_) do
    tournament = fixture(:tournament)
    %{tournament: tournament}
  end
end

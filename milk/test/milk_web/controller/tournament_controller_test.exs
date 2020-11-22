defmodule MilkWeb.TournamentControllerTest do
  use MilkWeb.ConnCase

  alias Milk.Tournaments
  alias Milk.Tournaments.Tournament

  @create_attrs %{
    capacity: 42,
    deadline: "2010-04-17T14:00:00Z",
    description: "some description",
    event_date: "2010-04-17T14:00:00Z",
    game_id: 42,
    master_id: 42,
    name: "some name",
    type: 42,
    url: "some url"
  }
  @update_attrs %{
    capacity: 43,
    deadline: "2011-05-18T15:01:01Z",
    description: "some updated description",
    event_date: "2011-05-18T15:01:01Z",
    game_id: 43,
    master_id: 43,
    name: "some updated name",
    type: 43,
    url: "some updated url"
  }
  @invalid_attrs %{capacity: nil, deadline: nil, description: nil, event_date: nil, game_id: nil, master_id: nil, name: nil, type: nil, url: nil}

  def fixture(:tournament) do
    {:ok, tournament} = Log.create_tournament(@create_attrs)
    tournament
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all tournament_log", %{conn: conn} do
      conn = get(conn, Routes.tournament_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create tournament" do
    test "renders tournament when data is valid", %{conn: conn} do
      conn = post(conn, Routes.tournament_path(conn, :create), tournament: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.tournament_path(conn, :show, id))

      assert %{
               "id" => id,
               "capacity" => 42,
               "deadline" => "2010-04-17T14:00:00Z",
               "description" => "some description",
               "event_date" => "2010-04-17T14:00:00Z",
               "game_id" => 42,
               "master_id" => 42,
               "name" => "some name",
               "type" => 42,
               "url" => "some url"
             } = json_response(conn, 200)["data"]
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

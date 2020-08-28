defmodule MilkWeb.TournamentLogControllerTest do
  use MilkWeb.ConnCase

  alias Milk.Log
  alias Milk.Log.TournamentLog

  @create_attrs %{
    name: "some name"
  }
  @update_attrs %{
    name: "some updated name"
  }
  @invalid_attrs %{name: nil}

  def fixture(:tournament_log) do
    {:ok, tournament_log} = Log.create_tournament_log(@create_attrs)
    tournament_log
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all tournament_log", %{conn: conn} do
      conn = get(conn, Routes.tournament_log_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create tournament_log" do
    test "renders tournament_log when data is valid", %{conn: conn} do
      conn = post(conn, Routes.tournament_log_path(conn, :create), tournament_log: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.tournament_log_path(conn, :show, id))

      assert %{
               "id" => id,
               "name" => "some name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.tournament_log_path(conn, :create), tournament_log: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update tournament_log" do
    setup [:create_tournament_log]

    test "renders tournament_log when data is valid", %{conn: conn, tournament_log: %TournamentLog{id: id} = tournament_log} do
      conn = put(conn, Routes.tournament_log_path(conn, :update, tournament_log), tournament_log: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.tournament_log_path(conn, :show, id))

      assert %{
               "id" => id,
               "name" => "some updated name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, tournament_log: tournament_log} do
      conn = put(conn, Routes.tournament_log_path(conn, :update, tournament_log), tournament_log: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete tournament_log" do
    setup [:create_tournament_log]

    test "deletes chosen tournament_log", %{conn: conn, tournament_log: tournament_log} do
      conn = delete(conn, Routes.tournament_log_path(conn, :delete, tournament_log))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.tournament_log_path(conn, :show, tournament_log))
      end
    end
  end

  defp create_tournament_log(_) do
    tournament_log = fixture(:tournament_log)
    %{tournament_log: tournament_log}
  end
end

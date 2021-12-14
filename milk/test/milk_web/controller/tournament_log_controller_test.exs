defmodule MilkWeb.TournamentLogControllerTest do
  use MilkWeb.ConnCase

  @create_attrs %{
    name: "some name"
  }
  @invalid_attrs %{name: nil}

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
      conn = post(conn, Routes.tournament_log_path(conn, :create), data: @create_attrs)
      assert %{"id" => _id} = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.tournament_log_path(conn, :create), data: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end
end

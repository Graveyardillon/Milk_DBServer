defmodule MilkWeb.AssistantLogControllerTest do
  use MilkWeb.ConnCase

  @create_attrs [%{
    tournament_id: 42,
    user_id: 42,
    create_time: ~U[2020-12-20 16:29:01.100311Z],
    update_time: ~U[2020-12-20 16:29:01.100311Z]
  }]
  @invalid_attrs [%{
    tournament_id: nil,
    user_id: nil,
    create_time: ~U[2020-12-20 16:29:01.100311Z],
    update_time: ~U[2020-12-20 16:29:01.100311Z]
  }]

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all assistant_log", %{conn: conn} do
      conn = get(conn, Routes.assistant_log_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create assistant_log" do
    test "renders assistant_log when data is valid", %{conn: conn} do
      conn = post(conn, Routes.assistant_log_path(conn, :create), data: @create_attrs)
      assert json_response(conn, 200)["result"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.assistant_log_path(conn, :create), data: @invalid_attrs)
      refute json_response(conn, 200)["result"]
    end
  end

  describe "show assistant_log" do
    test "renders assistant_log when data is valid", %{conn: conn} do
      conn = get(conn, Routes.assistant_log_path(conn, :show, 0))
      assert json_response(conn, 200)["result"]
    end

  end
end

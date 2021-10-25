defmodule MilkWeb.AssistantLogControllerTest do
  use MilkWeb.ConnCase

  @create_attrs [
    %{
      tournament_id: 42,
      user_id: 42,
      create_time: ~U[2020-12-20 16:29:01.100311Z],
      update_time: ~U[2020-12-20 16:29:01.100311Z]
    }
  ]
  @invalid_attrs %{
    tournament_id: nil,
    user_id: nil,
    create_time: ~U[2020-12-20 16:29:01.100311Z],
    update_time: ~U[2020-12-20 16:29:01.100311Z]
  }

  @update_attrs %{
    tournament_id: 40,
    user_id: 40
  }

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
      assert json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.assistant_log_path(conn, :create), data: [@invalid_attrs])
      refute json_response(conn, 200)["result"]
    end
  end

  describe "show assistant_log" do
    test "renders assistant_log when data is valid", %{conn: conn} do
      conn = post(conn, Routes.assistant_log_path(conn, :create), data: @create_attrs)
      assert id = json_response(conn, 200)["data"]["id"]
      conn = get(conn, Routes.assistant_log_path(conn, :show, id))
      assert json_response(conn, 200)["data"]
    end
  end

  describe "update assistant log" do
    test "renders assistant_log when data is valid", %{conn: conn} do
      conn = post(conn, Routes.assistant_log_path(conn, :create), data: @create_attrs)
      assert id = json_response(conn, 200)["data"]["id"]

      conn = patch(conn, Routes.assistant_log_path(conn, :update, id), assistant_log: @update_attrs)

      assert json_response(conn, 200)["data"] == %{
               "id" => id,
               "tournament_id" => @update_attrs.tournament_id,
               "user_id" => @update_attrs.user_id
             }
    end

    test "renders false when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.assistant_log_path(conn, :create), data: @create_attrs)
      assert id = json_response(conn, 200)["data"]["id"]

      conn = patch(conn, Routes.assistant_log_path(conn, :update, id), assistant_log: @invalid_attrs)

      assert json_response(conn, 200) == %{"result" => false}
    end
  end

  describe "delete assistant log" do
    test "renders assistant_log when data is valid", %{conn: conn} do
      conn = post(conn, Routes.assistant_log_path(conn, :create), data: @create_attrs)
      assert id = json_response(conn, 200)["data"]["id"]
      conn = delete(conn, Routes.assistant_log_path(conn, :update, id))
      assert response(conn, 204)
    end
  end
end

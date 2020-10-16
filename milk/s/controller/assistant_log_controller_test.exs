defmodule MilkWeb.AssistantLogControllerTest do
  use MilkWeb.ConnCase

  alias Milk.Log
  alias Milk.Log.AssistantLog

  @create_attrs %{
    tournament_id: 42,
    user_id: 42
  }
  @update_attrs %{
    tournament_id: 43,
    user_id: 43
  }
  @invalid_attrs %{tournament_id: nil, user_id: nil}

  def fixture(:assistant_log) do
    {:ok, assistant_log} = Log.create_assistant_log(@create_attrs)
    assistant_log
  end

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
      conn = post(conn, Routes.assistant_log_path(conn, :create), assistant_log: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.assistant_log_path(conn, :show, id))

      assert %{
               "id" => id,
               "tournament_id" => 42,
               "user_id" => 42
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.assistant_log_path(conn, :create), assistant_log: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update assistant_log" do
    setup [:create_assistant_log]

    test "renders assistant_log when data is valid", %{conn: conn, assistant_log: %AssistantLog{id: id} = assistant_log} do
      conn = put(conn, Routes.assistant_log_path(conn, :update, assistant_log), assistant_log: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.assistant_log_path(conn, :show, id))

      assert %{
               "id" => id,
               "tournament_id" => 43,
               "user_id" => 43
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, assistant_log: assistant_log} do
      conn = put(conn, Routes.assistant_log_path(conn, :update, assistant_log), assistant_log: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete assistant_log" do
    setup [:create_assistant_log]

    test "deletes chosen assistant_log", %{conn: conn, assistant_log: assistant_log} do
      conn = delete(conn, Routes.assistant_log_path(conn, :delete, assistant_log))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.assistant_log_path(conn, :show, assistant_log))
      end
    end
  end

  defp create_assistant_log(_) do
    assistant_log = fixture(:assistant_log)
    %{assistant_log: assistant_log}
  end
end

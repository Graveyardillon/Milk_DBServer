defmodule MilkWeb.EntrantLogControllerTest do
  use MilkWeb.ConnCase

  alias Milk.Log
  alias Milk.Log.EntrantLog

  @create_attrs %{
    entrant_id: 42,
    tournament_id: 42,
    user_id: 42,
    rank: 1,
    create_time: ~U[2020-12-20 16:29:01.100311Z],
    update_time: ~U[2020-12-20 16:29:01.100311Z]
  }
  @update_attrs %{
    entrant_id: 42,
    tournament_id: 43,
    user_id: 43,
    rank: 1
  }
  @invalid_attrs %{user_id: nil}

  def fixture(:entrant_log) do
    {:ok, entrant_log} = Log.create_entrant_log(@create_attrs)
    entrant_log
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all entrant_log", %{conn: conn} do
      conn = get(conn, Routes.entrant_log_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create entrant_log" do
    test "renders entrant_log when data is valid", %{conn: conn} do
      conn = post(conn, Routes.entrant_log_path(conn, :create), data: @create_attrs)
      assert %{"id" => id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.entrant_log_path(conn, :show, id))

      assert %{
               "id" => id,
               "user_id" => 42
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.entrant_log_path(conn, :create), data: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update entrant_log" do
    setup [:create_entrant_log]

    test "renders entrant_log when data is valid", %{
      conn: conn,
      entrant_log: %EntrantLog{id: id} = entrant_log
    } do
      conn = put(conn, Routes.entrant_log_path(conn, :update, entrant_log), entrant_log: @update_attrs)

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.entrant_log_path(conn, :show, id))

      assert %{
               "id" => id,
               "user_id" => 43
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, entrant_log: entrant_log} do
      conn = put(conn, Routes.entrant_log_path(conn, :update, entrant_log), entrant_log: @invalid_attrs)

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete entrant_log" do
    setup [:create_entrant_log]

    test "deletes chosen entrant_log", %{conn: conn, entrant_log: entrant_log} do
      conn = delete(conn, Routes.entrant_log_path(conn, :delete, entrant_log))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.entrant_log_path(conn, :show, entrant_log))
      end
    end
  end

  defp create_entrant_log(_) do
    entrant_log = fixture(:entrant_log)
    %{entrant_log: entrant_log}
  end
end

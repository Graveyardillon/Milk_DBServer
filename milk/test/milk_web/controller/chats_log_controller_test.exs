defmodule MilkWeb.ChatsLogControllerTest do
  use MilkWeb.ConnCase

  alias Milk.Log
  alias Milk.Log.ChatsLog

  @create_attrs %{
    "chat_room_id" => 42,
    "index" => 42,
    "user_id" => 42,
    "word" => "some word"
  }
  @update_attrs %{
    "chat_room_id" => 43,
    "index" => 43,
    "user_id" => 43,
    "word" => "some updated word"
  }
  @invalid_attrs %{
    "chat_room_id" => nil,
    "index" => nil,
    "user_id" => nil,
    "word" => nil
  }

  def fixture(:chats_log) do
    {:ok, chats_log} = Log.create_chats_log(@create_attrs)
    chats_log
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all chat_log", %{conn: conn} do
      conn = get(conn, Routes.chats_log_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create chats_log" do
    test "renders chats_log when data is valid", %{conn: conn} do
      conn = post(conn, Routes.chats_log_path(conn, :create), @create_attrs)
      assert %{"id" => id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.chats_log_path(conn, :show, id))

      assert %{
               "id" => _,
               "chat_room_id" => 42,
               "index" => 42,
               "user_id" => 42,
               "word" => "some word"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.chats_log_path(conn, :create), @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update chats_log" do
    setup [:create_chats_log]

    test "renders chats_log when data is valid", %{
      conn: conn,
      chats_log: %ChatsLog{id: id} = chats_log
    } do
      conn = put(conn, Routes.chats_log_path(conn, :update, chats_log), chats_log: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.chats_log_path(conn, :show, id))

      assert %{
               "id" => _,
               "chat_room_id" => 43,
               "index" => 43,
               "user_id" => 43,
               "word" => "some updated word"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, chats_log: chats_log} do
      conn = put(conn, Routes.chats_log_path(conn, :update, chats_log), chats_log: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete chats_log" do
    setup [:create_chats_log]

    test "deletes chosen chats_log", %{conn: conn, chats_log: chats_log} do
      conn = delete(conn, Routes.chats_log_path(conn, :delete, chats_log))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.chats_log_path(conn, :show, chats_log))
      end
    end
  end

  defp create_chats_log(_) do
    chats_log = fixture(:chats_log)
    %{chats_log: chats_log}
  end
end

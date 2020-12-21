defmodule MilkWeb.ChatRoomLogControllerTest do
  use MilkWeb.ConnCase

  alias Milk.Chat
  alias Milk.Log
  alias Milk.Log.ChatRoomLog

  @create_attrs %{
    "count" => 42,
    "last_chat" => "some last_chat",
    "name" => "some name"
  }
  @update_attrs %{
    "count" => 43,
    "last_chat" => "some updated last_chat",
    "name" => "some updated name"
  }
  @invalid_attrs %{
    "count" => nil,
    "last_chat" => nil,
    "name" => nil
  }

  def fixture(:chat_room_log) do
    chat_room = fixture(:chat_room)
    {:ok, chat_room_log} =
      @create_attrs
      |> Map.put("id", chat_room.id)
      |> Log.create_chat_room_log()
    chat_room_log
  end

  def fixture(:chat_room) do
    {:ok, chat_room} = Chat.create_chat_room(@create_attrs)
    chat_room
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all chat_room_log", %{conn: conn} do
      conn = get(conn, Routes.chat_room_log_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create chat_room_log" do
    test "renders chat_room_log when data is valid", %{conn: conn} do
      chat_room = fixture(:chat_room)
      conn = post(conn, Routes.chat_room_log_path(conn, :create), chat_room_log: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.chat_room_log_path(conn, :show, id))

      assert %{
               "id" => id,
               "count" => 42,
               "last_chat" => "some last_chat",
               "name" => "some name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.chat_room_log_path(conn, :create), chat_room_log: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update chat_room_log" do
    setup [:create_chat_room_log]

    test "renders chat_room_log when data is valid", %{conn: conn, chat_room_log: %ChatRoomLog{id: id} = chat_room_log} do
      conn = put(conn, Routes.chat_room_log_path(conn, :update, chat_room_log), chat_room_log: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.chat_room_log_path(conn, :show, id))

      assert %{
               "id" => id,
               "count" => 43,
               "last_chat" => "some updated last_chat",
               "name" => "some updated name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, chat_room_log: chat_room_log} do
      conn = put(conn, Routes.chat_room_log_path(conn, :update, chat_room_log), chat_room_log: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete chat_room_log" do
    setup [:create_chat_room_log]

    test "deletes chosen chat_room_log", %{conn: conn, chat_room_log: chat_room_log} do
      conn = delete(conn, Routes.chat_room_log_path(conn, :delete, chat_room_log))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.chat_room_log_path(conn, :show, chat_room_log))
      end
    end
  end

  defp create_chat_room_log(_) do
    chat_room_log = fixture(:chat_room_log)
    %{chat_room_log: chat_room_log}
  end
end

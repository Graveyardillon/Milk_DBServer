defmodule MilkWeb.ChatMemberLogControllerTest do
  use MilkWeb.ConnCase

  alias Milk.Log
  alias Milk.Log.ChatMemberLog

  @create_attrs %{
    authority: 42,
    chat_room_id: 42,
    user_id: 42
  }
  @update_attrs %{
    authority: 43,
    chat_room_id: 43,
    user_id: 43
  }
  @invalid_attrs %{authority: nil, chat_room_id: nil, user_id: nil}

  def fixture(:chat_member_log) do
    {:ok, chat_member_log} = Log.create_chat_member_log(@create_attrs)
    chat_member_log
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all chat_member_log", %{conn: conn} do
      conn = get(conn, Routes.chat_member_log_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create chat_member_log" do
    test "renders chat_member_log when data is valid", %{conn: conn} do
      conn = post(conn, Routes.chat_member_log_path(conn, :create), data: @create_attrs)
      assert %{"id" => id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.chat_member_log_path(conn, :show, id))

      assert %{
               "id" => id,
               "authority" => 42,
               "chat_room_id" => 42,
               "user_id" => 42
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.chat_member_log_path(conn, :create), data: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update chat_member_log" do
    setup [:create_chat_member_log]

    test "renders chat_member_log when data is valid", %{
      conn: conn,
      chat_member_log: %ChatMemberLog{id: id} = chat_member_log
    } do
      conn = put(conn, Routes.chat_member_log_path(conn, :update, chat_member_log), chat_member_log: @update_attrs)

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.chat_member_log_path(conn, :show, id))

      assert %{
               "id" => id,
               "authority" => 43,
               "chat_room_id" => 43,
               "user_id" => 43
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, chat_member_log: chat_member_log} do
      conn = put(conn, Routes.chat_member_log_path(conn, :update, chat_member_log), chat_member_log: @invalid_attrs)

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete chat_member_log" do
    setup [:create_chat_member_log]

    test "deletes chosen chat_member_log", %{conn: conn, chat_member_log: chat_member_log} do
      conn = delete(conn, Routes.chat_member_log_path(conn, :delete, chat_member_log))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.chat_member_log_path(conn, :show, chat_member_log))
      end
    end
  end

  defp create_chat_member_log(_) do
    chat_member_log = fixture(:chat_member_log)
    %{chat_member_log: chat_member_log}
  end
end

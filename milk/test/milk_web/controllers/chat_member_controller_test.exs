defmodule MilkWeb.ChatMemberControllerTest do
  use MilkWeb.ConnCase

  alias Milk.Chat
  alias Milk.Chat.ChatMember

  @create_attrs %{
    authority: 42
  }
  @update_attrs %{
    authority: 43
  }
  @invalid_attrs %{authority: nil}

  def fixture(:chat_member) do
    {:ok, chat_member} = Chat.create_chat_member(@create_attrs)
    chat_member
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all chat_member", %{conn: conn} do
      conn = get(conn, Routes.chat_member_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create chat_member" do
    test "renders chat_member when data is valid", %{conn: conn} do
      conn = post(conn, Routes.chat_member_path(conn, :create), chat_member: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.chat_member_path(conn, :show, id))

      assert %{
               "id" => id,
               "authority" => 42
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.chat_member_path(conn, :create), chat_member: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update chat_member" do
    setup [:create_chat_member]

    test "renders chat_member when data is valid", %{conn: conn, chat_member: %ChatMember{id: id} = chat_member} do
      conn = put(conn, Routes.chat_member_path(conn, :update, chat_member), chat_member: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.chat_member_path(conn, :show, id))

      assert %{
               "id" => id,
               "authority" => 43
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, chat_member: chat_member} do
      conn = put(conn, Routes.chat_member_path(conn, :update, chat_member), chat_member: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete chat_member" do
    setup [:create_chat_member]

    test "deletes chosen chat_member", %{conn: conn, chat_member: chat_member} do
      conn = delete(conn, Routes.chat_member_path(conn, :delete, chat_member))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.chat_member_path(conn, :show, chat_member))
      end
    end
  end

  defp create_chat_member(_) do
    chat_member = fixture(:chat_member)
    %{chat_member: chat_member}
  end
end

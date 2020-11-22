defmodule MilkWeb.ChatsControllerTest do
  use MilkWeb.ConnCase

  alias Milk.Chat
  alias Milk.Chat.Chats

  @create_attrs %{
    index: 42,
    word: "some word"
  }
  @update_attrs %{
    index: 43,
    word: "some updated word"
  }
  @invalid_attrs %{index: nil, word: nil}

  def fixture(:chats) do
    {:ok, chats} = Chat.create_chats(@create_attrs)
    chats
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all chat", %{conn: conn} do
      conn = get(conn, Routes.chats_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create chats" do
    test "renders chats when data is valid", %{conn: conn} do
      conn = post(conn, Routes.chats_path(conn, :create), chats: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.chats_path(conn, :show, id))

      assert %{
               "id" => id,
               "index" => 42,
               "word" => "some word"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.chats_path(conn, :create), chats: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update chats" do
    setup [:create_chats]

    test "renders chats when data is valid", %{conn: conn, chats: %Chats{id: id} = chats} do
      conn = put(conn, Routes.chats_path(conn, :update, chats), chats: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.chats_path(conn, :show, id))

      assert %{
               "id" => id,
               "index" => 43,
               "word" => "some updated word"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, chats: chats} do
      conn = put(conn, Routes.chats_path(conn, :update, chats), chats: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete chats" do
    setup [:create_chats]

    test "deletes chosen chats", %{conn: conn, chats: chats} do
      conn = delete(conn, Routes.chats_path(conn, :delete, chats))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.chats_path(conn, :show, chats))
      end
    end
  end

  defp create_chats(_) do
    chats = fixture(:chats)
    %{chats: chats}
  end
end

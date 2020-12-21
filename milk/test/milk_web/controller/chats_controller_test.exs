defmodule MilkWeb.ChatsControllerTest do
  use MilkWeb.ConnCase

  alias Milk.Accounts
  alias Milk.Chat
  alias Milk.Chat.Chats

  @create_attrs %{
    "index" => 42,
    "word" => "some word"
  }
  @update_attrs %{
    "index" => 4,
    "word" => "some updated word"
  }
  @invalid_attrs %{"index" => nil, "word" => nil}

  defp fixture(:chats) do
    user = fixture(:user)
    chat_room = fixture(:chat_room)
    Chat.create_chat_member(%{"user_id" => user.id, "chat_room_id" => chat_room.id})

    {:ok, chats} =
      @create_attrs
      |> Map.put("user_id", user.id)
      |> Map.put("chat_room_id", chat_room.id)
      |> Chat.create_chats()
    chats
  end

  defp fixture(:user) do
    user_valid_attrs = %{"icon_path" => "some icon_path", "language" => "some language", "name" => "some name", "notification_number" => 42, "point" => 42, "email" => "some@email.com", "logout_fl" => true, "password" => "S1ome password"}
    {:ok, user} =
      user_valid_attrs
      |> Accounts.create_user()

    Accounts.get_user(user.id)
  end

  defp fixture(:chat_room) do
    attrs = %{"count" => 42, "last_chat" => "some last_chat", "name" => "some name"}
    {:ok, chat_room} = Chat.create_chat_room(attrs)
    chat_room
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create chats" do
    test "renders chats when data is valid", %{conn: conn} do
      user = fixture(:user)
      chat_room = fixture(:chat_room)
      Chat.create_chat_member(%{"user_id" => user.id, "chat_room_id" => chat_room.id})
      attrs =
        @create_attrs
        |> Map.put("user_id", user.id)
        |> Map.put("chat_room_id", chat_room.id)

      conn = post(conn, Routes.chats_path(conn, :create), chat: attrs)
      assert %{"id" => id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.chats_path(conn, :show, id))

      assert %{
        "id" => id,
        "index" => 43,
        "word" => "some word"
      } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.chats_path(conn, :create), chat: @invalid_attrs)
      refute json_response(conn, 200)["result"]
    end
  end

  describe "update chats" do
    setup [:create_chats]

    test "renders chats when data is valid", %{conn: conn, chats: %Chats{id: id} = chats} do
      conn = put(conn, Routes.chats_path(conn, :update, chats), chat: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.chats_path(conn, :show, id))

      assert %{
        "id" => id,
        "index" => 43,
        "word" => "some updated word"
      } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, chats: chats} do
      conn = put(conn, Routes.chats_path(conn, :update, chats), chat: @invalid_attrs)
      refute json_response(conn, 200)["result"]
    end
  end

  describe "delete chats" do
    setup [:create_chats]

    test "deletes chosen chats", %{conn: conn, chats: chats} do
      conn = delete(conn, Routes.chats_path(conn, :delete, %{chat_room_id: chats.chat_room_id, index: chats.index}))
      assert response(conn, 204)

      # assert_error_sent 404, fn ->
      #   get(conn, Routes.chats_path(conn, :show, chats))
      # end
    end
  end

  defp create_chats(_) do
    chats = fixture(:chats)
    %{chats: chats}
  end
end

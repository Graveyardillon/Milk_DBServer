defmodule MilkWeb.ChatRoomControllerTest do
  use MilkWeb.ConnCase

  alias Milk.{
    Chat,
    Accounts
  }

  alias Milk.Chat.ChatRoom

  @create_attrs %{count: 42, last_chat: "some last_chat", name: "some name"}
  @update_attrs %{count: 43, last_chat: "some updated last_chat", name: "some updated name"}
  @invalid_attrs %{count: nil, last_chat: nil, name: nil}

  def fixture(:chat_room) do
    {:ok, chat_room} = Chat.create_chat_room(@create_attrs)
    chat_room
  end

  defp fixture_user(n \\ 0) do
    attrs = %{
      "icon_path" => "some icon_path",
      "language" => "some language",
      "name" => to_string(n) <> "some name",
      "notification_number" => 42,
      "point" => 42,
      "email" => to_string(n) <> "some@email.com",
      "logout_fl" => true,
      "password" => "S1ome password"
    }

    {:ok, user} = Accounts.create_user(attrs)
    user
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create chat_room" do
    test "renders chat_room when data is valid", %{conn: conn} do
      conn = post(conn, Routes.chat_room_path(conn, :create), chat_room: @create_attrs)
      assert %{"id" => id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.chat_room_path(conn, :show, %{"id" => id}))

      assert %{
               "id" => id,
               "count" => 42,
               "last_chat" => "some last_chat",
               "name" => "some name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.chat_room_path(conn, :create), chat_room: @invalid_attrs)
      refute json_response(conn, 200)["data"]
    end
  end

  describe "update chat_room" do
    setup [:create_chat_room]

    test "renders chat_room when data is valid", %{
      conn: conn,
      chat_room: %ChatRoom{id: id} = chat_room
    } do
      conn = put(conn, Routes.chat_room_path(conn, :update, chat_room), chat_room: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.chat_room_path(conn, :show, %{"id" => id}))

      assert %{
               "id" => id,
               "count" => 43,
               "last_chat" => "some updated last_chat",
               "name" => "some updated name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, chat_room: chat_room} do
      conn = put(conn, Routes.chat_room_path(conn, :update, chat_room), chat_room: @invalid_attrs)
      refute json_response(conn, 200)["data"]
    end
  end

  describe "delete chat_room" do
    setup [:create_chat_room]

    test "deletes chosen chat_room", %{conn: conn, chat_room: chat_room} do
      conn = delete(conn, Routes.chat_room_path(conn, :delete, chat_room))
      assert response(conn, 204)

      # conn = get(conn, Routes.chat_room_path(conn, :show, chat_room))
      # refute json_response(conn, 200)["result"]
    end
  end

  describe "private_room" do
    setup [:create_chat_room]

    test "private_room works fine with valid data", %{conn: conn, chat_room: _chat_room} do
      user1 = fixture_user(1)
      user2 = fixture_user(2)

      conn =
        get(
          conn,
          Routes.chat_room_path(conn, :private_room, %{
            "my_id" => user1.id,
            "partner_id" => user2.id
          })
        )

      assert response(conn, 200)
    end
  end

  describe "private_rooms" do
    test "works", %{conn: conn} do
      user1 = fixture_user(1)
      user2 = fixture_user(2)

      chat_rooms =
        1..5
        |> Enum.to_list()
        |> Enum.map(fn n ->
          %{"name" => "test room" <> to_string(n), "is_private" => true}
          |> Chat.create_chat_room()
          |> elem(1)
        end)

      chat_room_id_list = Enum.map(chat_rooms, fn room -> room.id end)

      conn = get(conn, Routes.chat_room_path(conn, :private_rooms), user_id: user1.id)

      json_response(conn, 200)
      |> Map.get("data")
      |> length()
      |> (fn len ->
            assert len == 0
          end).()

      chat_rooms
      |> Enum.each(fn room ->
        %{"user_id" => user1.id, "chat_room_id" => room.id}
        |> Chat.create_chat_member()

        %{"user_id" => user2.id, "chat_room_id" => room.id}
        |> Chat.create_chat_member()
      end)

      conn = get(conn, Routes.chat_room_path(conn, :private_rooms), user_id: user1.id)

      json_response(conn, 200)
      |> Map.get("data")
      |> Enum.map(fn room ->
        assert room["room_id"] in chat_room_id_list
        assert room["authority"] == 0
        refute room["last_chat"]
      end)
      |> length()
      |> (fn len ->
            assert len == length(chat_rooms)
          end).()
    end
  end

  defp create_chat_room(_) do
    chat_room = fixture(:chat_room)
    %{chat_room: chat_room}
  end
end

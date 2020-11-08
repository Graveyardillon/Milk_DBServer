defmodule MilkWeb.ChatRoomController do
  use MilkWeb, :controller

  alias Milk.Chat
  alias Milk.Chat.ChatRoom

  # action_fallback MilkWeb.FallbackController

  def index(conn, _params) do
    chat_room = Chat.list_chat_room()
    if (chat_room) do
      render(conn, "index.json", chat_room: chat_room)
    else
      render(conn, "error.json", error: nil)
    end
  end

  def create(conn, %{"chat_room" => chat_room_params}) do
    case Chat.create_chat_room(chat_room_params) do
    {:ok, %ChatRoom{} = chat_room} ->
      conn
      # |> put_status(:created)
      # |> put_resp_header("location", Routes.chat_room_path(conn, :show, chat_room))
      |> render("show.json", chat_room: chat_room)
    {:error, error} ->
      render(conn, "error.json", error: error)
    _ -> render(conn, "error.json", error: nil)
    end
  end

  def show(conn, %{"id" => id}) do
    chat_room = Chat.get_chat_room(id)
    if (chat_room) do
      render(conn, "show.json", chat_room: chat_room)
    else
      render(conn, "error.json", error: nil)
    end
  end

  def update(conn, %{"id" => id, "chat_room" => chat_room_params}) do
    chat_room = Chat.get_chat_room(id)
    if (chat_room) do
      with {:ok, %ChatRoom{} = chat_room} <- Chat.update_chat_room(chat_room, chat_room_params) do
        render(conn, "show.json", chat_room: chat_room)
      else
        _ -> render(conn, "error.json", error: nil)
      end
    else
      # IDが存在しない
      render(conn, "error.json", error: nil)
    end
  end

  def delete(conn, %{"id" => id}) do
    chat_room = Chat.get_all_chat(id)
    if (chat_room) do
      with {:ok, %ChatRoom{}} <- Chat.delete_chat_room(chat_room) do
        send_resp(conn, :no_content, "")
      end
    end
  end

  def my_rooms(conn, %{"user_id" => id}) do
    chat_rooms = Chat.get_chat_rooms_by_user_id(id)
    if chat_rooms do
      render(conn, "index.json", chat_room: chat_rooms)
    else
      render(conn, "error.json", error: nil)
    end
  end

  def private_rooms(conn, %{"user_id" => id}) do
    user_id =
    if is_binary(id) do
      String.to_integer(id)
    else
      id
    end

    chat_with_user = Chat.get_private_chat_rooms(user_id)
          |> Enum.map(fn room ->
            user = Chat.get_user_in_private_room(room.id, user_id)
            %{
              id: user.id,
              room_id: room.id,
              name: user.name,
              email: user.auth.email,
              last_chat: room.last_chat,
              count: room.count,
              is_private: room.is_private
            }
          end)
    if chat_with_user do
      render(conn, "chat_room_with_user.json", info: chat_with_user)
    else
      render(conn, "error.json", error: nil)
    end
  end
end

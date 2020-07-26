defmodule MilkWeb.ChatRoomController do
  use MilkWeb, :controller

  alias Milk.Chat
  alias Milk.Chat.ChatRoom

  action_fallback MilkWeb.FallbackController

  def index(conn, _params) do
    chat_room = Chat.list_chat_room()
    render(conn, "index.json", chat_room: chat_room)
  end

  def create(conn, %{"chat_room" => chat_room_params}) do
    with {:ok, %ChatRoom{} = chat_room} <- Chat.create_chat_room(chat_room_params) do
      conn
      # |> put_status(:created)
      # |> put_resp_header("location", Routes.chat_room_path(conn, :show, chat_room))
      |> render("show.json", chat_room: chat_room)
    end
  end

  def show(conn, %{"id" => id}) do
    chat_room = Chat.get_chat_room!(id)
    render(conn, "show.json", chat_room: chat_room)
  end

  def update(conn, %{"id" => id, "chat_room" => chat_room_params}) do
    chat_room = Chat.get_chat_room!(id)

    with {:ok, %ChatRoom{} = chat_room} <- Chat.update_chat_room(chat_room, chat_room_params) do
      render(conn, "show.json", chat_room: chat_room)
    end
  end

  def delete(conn, %{"id" => id}) do
    chat_room = Chat.get_all_chat(id) |> IO.inspect

    with {:ok, %ChatRoom{}} <- Chat.delete_chat_room(chat_room) do
      send_resp(conn, :no_content, "")
    end
  end
end

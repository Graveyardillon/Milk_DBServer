defmodule MilkWeb.ChatRoomLogController do
  use MilkWeb, :controller

  alias Milk.Log
  alias Milk.Log.ChatRoomLog

  action_fallback MilkWeb.FallbackController

  def index(conn, _params) do
    chat_room_log = Log.list_chat_room_log()
    render(conn, "index.json", chat_room_log: chat_room_log)
  end

  def create(conn, %{"data" => chat_room_log_params}) do
    with {:ok, %ChatRoomLog{} = chat_room_log} <- Log.create_chat_room_log(chat_room_log_params) do
      conn
      |> put_status(:created)
      |> render("show.json", chat_room_log: chat_room_log)
    end
  end

  def show(conn, %{"id" => id}) do
    chat_room_log = Log.get_chat_room_log!(id)
    render(conn, "show.json", chat_room_log: chat_room_log)
  end

  def update(conn, %{"id" => id, "chat_room_log" => chat_room_log_params}) do
    chat_room_log = Log.get_chat_room_log!(id)

    with {:ok, %ChatRoomLog{} = chat_room_log} <-
           Log.update_chat_room_log(chat_room_log, chat_room_log_params) do
      render(conn, "show.json", chat_room_log: chat_room_log)
    end
  end

  def delete(conn, %{"id" => id}) do
    chat_room_log = Log.get_chat_room_log!(id)

    with {:ok, %ChatRoomLog{}} <- Log.delete_chat_room_log(chat_room_log) do
      send_resp(conn, :no_content, "")
    end
  end
end

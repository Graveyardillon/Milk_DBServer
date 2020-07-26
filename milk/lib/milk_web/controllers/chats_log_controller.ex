defmodule MilkWeb.ChatsLogController do
  use MilkWeb, :controller

  alias Milk.Log
  alias Milk.Log.ChatsLog

  action_fallback MilkWeb.FallbackController

  def index(conn, _params) do
    chat_log = Log.list_chat_log()
    render(conn, "index.json", chat_log: chat_log)
  end

  def create(conn, %{"chats_log" => chats_log_params}) do
    with {:ok, %ChatsLog{} = chats_log} <- Log.create_chats_log(chats_log_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.chats_log_path(conn, :show, chats_log))
      |> render("show.json", chats_log: chats_log)
    end
  end

  def show(conn, %{"id" => id}) do
    chats_log = Log.get_chats_log!(id)
    render(conn, "show.json", chats_log: chats_log)
  end

  def update(conn, %{"id" => id, "chats_log" => chats_log_params}) do
    chats_log = Log.get_chats_log!(id)

    with {:ok, %ChatsLog{} = chats_log} <- Log.update_chats_log(chats_log, chats_log_params) do
      render(conn, "show.json", chats_log: chats_log)
    end
  end

  def delete(conn, %{"id" => id}) do
    chats_log = Log.get_chats_log!(id)

    with {:ok, %ChatsLog{}} <- Log.delete_chats_log(chats_log) do
      send_resp(conn, :no_content, "")
    end
  end
end

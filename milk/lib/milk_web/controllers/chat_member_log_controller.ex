defmodule MilkWeb.ChatMemberLogController do
  use MilkWeb, :controller

  alias Milk.Log
  alias Milk.Log.ChatMemberLog

  action_fallback MilkWeb.FallbackController

  def index(conn, _params) do
    chat_member_log = Log.list_chat_member_log()
    render(conn, "index.json", chat_member_log: chat_member_log)
  end

  def create(conn, %{"chat_member_log" => chat_member_log_params}) do
    with {:ok, %ChatMemberLog{} = chat_member_log} <- Log.create_chat_member_log(chat_member_log_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.chat_member_log_path(conn, :show, chat_member_log))
      |> render("show.json", chat_member_log: chat_member_log)
    end
  end

  def show(conn, %{"id" => id}) do
    chat_member_log = Log.get_chat_member_log!(id)
    render(conn, "show.json", chat_member_log: chat_member_log)
  end

  def update(conn, %{"id" => id, "chat_member_log" => chat_member_log_params}) do
    chat_member_log = Log.get_chat_member_log!(id)

    with {:ok, %ChatMemberLog{} = chat_member_log} <- Log.update_chat_member_log(chat_member_log, chat_member_log_params) do
      render(conn, "show.json", chat_member_log: chat_member_log)
    end
  end

  def delete(conn, %{"id" => id}) do
    chat_member_log = Log.get_chat_member_log!(id)

    with {:ok, %ChatMemberLog{}} <- Log.delete_chat_member_log(chat_member_log) do
      send_resp(conn, :no_content, "")
    end
  end
end

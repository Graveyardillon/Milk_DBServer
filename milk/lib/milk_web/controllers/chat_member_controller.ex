defmodule MilkWeb.ChatMemberController do
  use MilkWeb, :controller

  alias Milk.Chat
  alias Milk.Chat.ChatMember

  action_fallback MilkWeb.FallbackController

  def index(conn, %{"chat_member" => params}) do
    chat_member = Chat.list_chat_member(params)
    render(conn, "index.json", chat_member: chat_member)
  end

  def create(conn, %{"chat_member" => params}) do
    with {:ok, %ChatMember{} = chat_member} <- Chat.create_chat_member(params) do
      conn
      # |> put_status(:created)
      # |> put_resp_header("location", Routes.chat_member_path(conn, :show, chat_member))
      |> render("show.json", chat_member: chat_member)
    else
      _ ->
        json(conn, %{result: false})
    end
  end

  def show(conn, %{"id" => id}) do
    chat_member = Chat.get_chat_member(id)
    render(conn, "show.json", chat_member: chat_member)
  end

  def update(conn, %{"id" => id, "chat_member" => chat_member_params}) do
    chat_member = Chat.get_chat_member!(id)

    with {:ok, %ChatMember{} = chat_member} <- Chat.update_chat_member(chat_member, chat_member_params) do
      render(conn, "show.json", chat_member: chat_member)
    end
  end

  def delete(conn, %{"chat_room_id" => chat_room_id, "user_id" => user_id}) do
    chat_member = Chat.get_member(chat_room_id, user_id)

    with {:ok, %ChatMember{}} <- Chat.delete_chat_member(chat_member) do
      send_resp(conn, :no_content, "")
    end
  end
end

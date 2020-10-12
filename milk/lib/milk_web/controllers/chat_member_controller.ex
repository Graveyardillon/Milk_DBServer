defmodule MilkWeb.ChatMemberController do
  use MilkWeb, :controller

  alias Milk.Chat
  alias Milk.Chat.ChatMember

  action_fallback MilkWeb.FallbackController

  def index(conn, %{"chat_member" => params}) do
    chat_member = Chat.list_chat_member(params)
    if (chat_member) do
      render(conn, "index.json", chat_member: chat_member)
    else
      render(conn, "error.json", error: nil)
    end
  end

  def create(conn, %{"chat_member" => params}) do
    case Chat.create_chat_member(params) do
    {:ok, %ChatMember{} = chat_member} ->
      conn
      # |> put_status(:created)
      # |> put_resp_header("location", Routes.chat_member_path(conn, :show, chat_member))
      |> render("show.json", chat_member: chat_member)
    {:error, error} ->
      render(conn, "error.json", error: error)
    _ ->
      render(conn, "error.json", error: nil)
    end
  end

  def show(conn, %{"id" => id}) do
    chat_member = Chat.get_chat_member(id)
    if(chat_member) do
      render(conn, "show.json", chat_member: chat_member)
    else
      render(conn, "error.json", error: nil)
    end
  end

  def update(conn, %{"id" => id, "chat_member" => chat_member_params}) do
    chat_member = Chat.get_chat_member!(id)
    if (chat_member) do
      case Chat.update_chat_member(chat_member, chat_member_params) do
      {:ok, %ChatMember{} = chat_member} -> 
        render(conn, "show.json", chat_member: chat_member)
      {:error, error} ->
        render(conn, "error.json", error: error)
      _ ->
        render(conn, "error.json", error: nil)
      end
    else
      render(conn, "error.json", error: nil)
    end
  end

  def delete(conn, %{"chat_room_id" => chat_room_id, "user_id" => user_id}) do
    chat_member = Chat.get_member(chat_room_id, user_id)
    if (chat_member) do
      with {:ok, %ChatMember{}} <- Chat.delete_chat_member(chat_member) do
        send_resp(conn, :no_content, "")
      end
    # else
    #   render(conn, "error.json", error: nil)
    end
  end
end

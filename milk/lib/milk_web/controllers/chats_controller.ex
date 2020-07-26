defmodule MilkWeb.ChatsController do
  use MilkWeb, :controller

  alias Milk.Chat
  alias Milk.Chat.Chats

  # action_fallback MilkWeb.FallbackController

  def index(conn, %{"chat" => params}) do
    chat = Chat.list_chat(params)
    render(conn, "index.json", chat: chat)
  end

  def create(conn, %{"chat" => chats_params}) do
    with {:ok, %Chats{} = chats} <- Chat.create_chats(chats_params) do
      IO.inspect chats
      conn
      # |> put_status(:created)
      # |> put_resp_header("location", Routes.chats_path(conn, :show, chats))
      |> render("show.json", chats: chats)
    end
  end

  def sync(conn, %{"user_id" => user_id, "year" => year, "month" => month, "day" => day, "hour" => hour, "minute" => minute, "second" => second}) do
    %DateTime{year: year, month: month, day: day, hour: hour, minute: minute, second: second, time_zone: "Asia/Tokyo", utc_offset: 32400, zone_abbr: "JST", std_offset: 0}
    |> Chat.sync(user_id)
    json(conn, %{result: true})
  end

  def get_latest(conn, %{"id" => id}) do
    chats = Chat.get_latest_chat(id)
    render(conn, "index.json", chat: chats)
  end

  def show(conn, %{"id" => id}) do
    chats = Chat.get_chats!(id)
    render(conn, "show.json", chats: chats)
  end

  def update(conn, %{"id" => id, "chat" => chats_params}) do
    chats = Chat.get_chats!(id)

    with {:ok, %Chats{} = chats} <- Chat.update_chats(chats, chats_params) do
      render(conn, "show.json", chats: chats)
    end
  end

  def delete(conn, %{"chat_room_id" => chat_room_id, "index" => index}) do
    chats = Chat.get_chat(chat_room_id, index)

    with {:ok, %Chats{}} <- Chat.delete_chats(chats) do
      send_resp(conn, :no_content, "")
    end
  end
end

defmodule MilkWeb.ChatsController do
  use MilkWeb, :controller

  alias Milk.Chat
  alias Milk.Chat.Chats

  # action_fallback MilkWeb.FallbackController

  def index(conn, %{"chat" => params}) do
    chat = Chat.list_chat(params)
    if (chat) do
      render(conn, "index.json", chat: chat)
    else
      render(conn, "error.json", error: nil)
    end
  end

  def create(conn, %{"chat" => chats_params}) do
    case Chat.create_chats(chats_params) do
    {:ok, %Chats{} = chats} ->
      conn
      # |> put_status(:created)
      # |> put_resp_header("location", Routes.chats_path(conn, :show, chats))
      |> render("show.json", chats: chats)
    {:error, error} ->
      render(conn, "error.json", error: error)
    _ -> 
      render(conn, "error.json", error: nil)
    end
  end

  def sync(conn, %{"user_id" => user_id, "year" => year, "month" => month, "day" => day, "hour" => hour, "minute" => minute, "second" => second}) do
    %DateTime{year: year, month: month, day: day, hour: hour, minute: minute, second: second, time_zone: "Asia/Tokyo", utc_offset: 32400, zone_abbr: "JST", std_offset: 0}
    |> Chat.sync(user_id)
    json(conn, %{result: true})
  end

  def get_latest(conn, %{"id" => id}) do
    chats = Chat.get_latest_chat(id)
    if(chats) do
      render(conn, "index.json", chat: chats)
    else
      render(conn, "error.json", error: nil)
    end
  end

  def show(conn, %{"id" => id}) do
    chats = Chat.get_chats!(id)
    if (chats) do
      render(conn, "show.json", chats: chats)
    else
      render(conn, "error.json", error: nil)
    end
  end

  def update(conn, %{"id" => id, "chat" => chats_params}) do
    chats = Chat.get_chats!(id)
    if (chats) do
      with {:ok, %Chats{} = chats} <- Chat.update_chats(chats, chats_params) do
        render(conn, "show.json", chats: chats)
      else
        _ -> render(conn, "error.json", error: nil)
      end
    else
      render(conn, "error.json", error: nil)
    end
  end

  def delete(conn, %{"chat_room_id" => chat_room_id, "index" => index}) do
    chats = Chat.get_chat(chat_room_id, index)
    if (chats) do
      with {:ok, %Chats{}} <- Chat.delete_chats(chats) do
        send_resp(conn, :no_content, "")
      end
    end
  end

  def create_dialogue(conn, %{"chat" => chats_params}) do
    case Chat.dialogue(chats_params) do
      {:ok, %Chats{} = chats} ->
        conn
        # |> put_status(:created)
        # |> put_resp_header("location", Routes.chats_path(conn, :show, chats))
        |> render("show.json", chats: chats)
      {:error, error} ->
        render(conn, "error.json", error: error)
      _ -> 
        render(conn, "error.json", error: nil)
    end
  end
  
  def create_dialogue(conn, %{"chat_group" => chats_params}) do
    case Chat.dialogue(chats_params) do
      {:ok, %Chats{} = chats} ->
        members = Chat.get_chat_members_of_room(chats.chat_room_id)
                  |> Enum.map(fn member ->
                    member.id
                  end)

        conn
        |> render("show.json", chats: chats, members: members)
      {:error, error} ->
        render(conn, "error.json", error: error)
      _ -> 
        render(conn, "error.json", error: nil)
    end
  end
end

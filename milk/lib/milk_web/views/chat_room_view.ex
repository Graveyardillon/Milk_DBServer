defmodule MilkWeb.ChatRoomView do
  use MilkWeb, :view

  alias Common.Tools
  alias MilkWeb.ChatRoomView

  def render("index.json", %{chat_room: chat_room}) do
    %{data: render_many(chat_room, ChatRoomView, "chat_room.json")}
  end

  def render("show.json", %{chat_room: chat_room}) do
    %{data: render_one(chat_room, ChatRoomView, "chat_room.json")}
  end

  def render("chat_room.json", %{chat_room: chat_room}) do
    %{
      id: chat_room.id,
      name: chat_room.name,
      last_chat: chat_room.last_chat,
      count: chat_room.count,
      is_private: chat_room.is_private,
      authority: chat_room.authority
    }
  end

  def render("chat_rooms_with_user.json", %{info: info}) do
    %{
      data:
        Enum.map(info, fn i ->
          %{
            id: i.id,
            room_id: i.room_id,
            name: i.name,
            email: i.email,
            last_chat: i.last_chat,
            count: i.count,
            is_private: i.is_private,
            authority: i.autority,
            icon_path: i.icon_path
          }
        end)
    }
  end

  def render("chat_room_with_user.json", %{info: info}) do
    %{
      data: %{
        id: info.id,
        room_id: info.room_id,
        name: info.name,
        email: info.email,
        last_chat: info.last_chat,
        count: info.count,
        is_private: info.is_private,
        icon_path: info.icon_path
      }
    }
  end

  def render("error.json", %{error: error}) do
    if(error) do
      %{result: false, error: Tools.create_error_message(error), data: nil}
    else
      %{result: false, error: nil, data: nil}
    end
  end
end

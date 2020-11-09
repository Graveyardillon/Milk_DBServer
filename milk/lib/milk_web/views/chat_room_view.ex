defmodule MilkWeb.ChatRoomView do
  use MilkWeb, :view
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
      is_private: chat_room.is_private
    }
  end

  def render("chat_rooms_with_user.json", %{info: info}) do
    %{
      data: Enum.map(info, fn i -> 
        %{
          id: i.id,
          room_id: i.room_id,
          name: i.name,
          email: i.email,
          last_chat: i.last_chat,
          count: i.count,
          is_private: i.is_private
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
        is_private: info.is_private
      }
    }
  end

  def render("error.json", %{error: error}) do
    if(error) do
      %{result: false, error: create_message(error), data: nil}
    else
      %{result: false, error: nil, data: nil}
    end
  end

  def create_message(error) do
    Enum.reduce(error, "",fn {key, value}, acc -> to_string(key) <> " "<> elem(value,0) <> ", "<> acc end)
  end
end

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
    %{id: chat_room.id,
      name: chat_room.name,
      last_chat: chat_room.last_chat,
      count: chat_room.count}
  end
end

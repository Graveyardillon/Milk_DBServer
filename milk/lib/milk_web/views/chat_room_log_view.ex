defmodule MilkWeb.ChatRoomLogView do
  use MilkWeb, :view
  alias MilkWeb.ChatRoomLogView

  def render("index.json", %{chat_room_log: chat_room_log}) do
    %{data: render_many(chat_room_log, ChatRoomLogView, "chat_room_log.json"), result: true}
  end

  def render("show.json", %{chat_room_log: chat_room_log}) do
    %{data: render_one(chat_room_log, ChatRoomLogView, "chat_room_log.json"), result: true}
  end

  def render("chat_room_log.json", %{chat_room_log: chat_room_log}) do
    %{id: chat_room_log.id,
      name: chat_room_log.name,
      last_chat: chat_room_log.last_chat,
      count: chat_room_log.count}
  end

end

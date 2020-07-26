defmodule MilkWeb.ChatsLogView do
  use MilkWeb, :view
  alias MilkWeb.ChatsLogView

  def render("index.json", %{chat_log: chat_log}) do
    %{data: render_many(chat_log, ChatsLogView, "chats_log.json")}
  end

  def render("show.json", %{chats_log: chats_log}) do
    %{data: render_one(chats_log, ChatsLogView, "chats_log.json")}
  end

  def render("chats_log.json", %{chats_log: chats_log}) do
    %{id: chats_log.id,
      chat_room_id: chats_log.chat_room_id,
      word: chats_log.word,
      user_id: chats_log.user_id,
      index: chats_log.index}
  end
end

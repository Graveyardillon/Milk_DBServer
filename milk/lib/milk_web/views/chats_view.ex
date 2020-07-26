defmodule MilkWeb.ChatsView do
  use MilkWeb, :view
  alias MilkWeb.ChatsView

  def render("index.json", %{chat: chat}) do
    %{data: render_many(chat, ChatsView, "chats.json")}
  end

  def render("show.json", %{chats: chats}) do
    %{data: render_one(chats, ChatsView, "chats.json")}
  end

  def render("chats.json", %{chats: chats}) do
    IO.inspect chats
    %{id: chats.id,
      word: chats.word,
      index: chats.index}
  end
end

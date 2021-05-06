defmodule MilkWeb.ChatsView do
  use MilkWeb, :view

  alias Common.Tools
  alias MilkWeb.ChatsView

  def render("index.json", %{chat: chat}) do
    %{data: render_many(chat, ChatsView, "chats.json"), result: true}
  end

  def render("show.json", %{chats: chats, members: members}) do
    %{
      data: render_one(chats, ChatsView, "chats.json"),
      members: members,
      result: true
    }
  end

  def render("show.json", %{chats: chats}) do
    %{data: render_one(chats, ChatsView, "chats.json"), result: true}
  end

  def render("chats.json", %{chats: chats}) do
    %{
      id: chats.id,
      word: chats.word,
      index: chats.index
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

defmodule MilkWeb.ChatMemberView do
  use MilkWeb, :view

  alias Common.Tools
  alias MilkWeb.ChatMemberView

  def render("index.json", %{chat_member: chat_member}) do
    %{data: render_many(chat_member, ChatMemberView, "chat_member.json"), result: true}
  end

  def render("show.json", %{chat_member: chat_member}) do
    %{data: render_one(chat_member, ChatMemberView, "chat_member.json"), result: true}
  end

  def render("chat_member.json", %{chat_member: chat_member}) do
    %{
      id: chat_member.id,
      authority: chat_member.authority,
      user_id: chat_member.user_id,
      chat_room_id: chat_member.chat_room_id
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

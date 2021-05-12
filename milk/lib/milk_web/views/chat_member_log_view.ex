defmodule MilkWeb.ChatMemberLogView do
  use MilkWeb, :view
  alias MilkWeb.ChatMemberLogView

  def render("index.json", %{chat_member_log: chat_member_log}) do
    %{data: render_many(chat_member_log, ChatMemberLogView, "chat_member_log.json")}
  end

  def render("show.json", %{chat_member_log: chat_member_log}) do
    %{data: render_one(chat_member_log, ChatMemberLogView, "chat_member_log.json")}
  end

  def render("chat_member_log.json", %{chat_member_log: chat_member_log}) do
    %{
      id: chat_member_log.id,
      chat_room_id: chat_member_log.chat_room_id,
      user_id: chat_member_log.user_id,
      authority: chat_member_log.authority
    }
  end
end

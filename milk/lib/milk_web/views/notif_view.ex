defmodule MilkWeb.NotifView do
  use MilkWeb, :view
  alias MilkWeb.NotifView

  def render("list.json", %{notif: notifs}) do
    %{data: render_many(notifs, NotifView, "notif.json"), result: true}
  end

  def render("show.json", %{notif: notif}) do
    %{data: render_one(notif, NotifView, "notif.json"), result: true}
  end

  def render("notif.json", %{notif: notif}) do
    %{
      id: notif.id,
      content: notif.content,
      user_id: notif.user_id,
      data: notif.data,
      process_code: notif.process_code,
      datetime: notif.update_time,
      username: notif.user.name,
      icon_path: notif.user.icon_path
    }
  end
end
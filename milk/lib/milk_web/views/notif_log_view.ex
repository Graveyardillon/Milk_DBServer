defmodule MilkWeb.NotifLogView do
  use MilkWeb, :view
  alias MilkWeb.NotifLogView

  def render("list.json", %{notif: notifs}) do
    %{data: render_many(notifs, NotifLogView, "notif_log.json"), result: true}
  end

  def render("show.json", %{notif: notif}) do
    %{data: render_one(notif, NotifLogView, "notif_log.json"), result: true}
  end

  def render("notif_log.json", %{notif_log: notif}) do
    %{
      id: notif.id,
      content: notif.content,
      user_id: notif.user_id,
      datetime: notif.update_time
    }
  end
end
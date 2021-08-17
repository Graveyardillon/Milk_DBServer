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
      title: notif.title,
      body_text: notif.body_text,
      user_id: notif.user_id,
      process_id: notif.process_id,
      datetime: notif.update_time
    }
  end
end

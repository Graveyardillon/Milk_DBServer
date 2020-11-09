defmodule MilkWeb.NotifLogController do
  use MilkWeb, :controller

  alias Milk.Notif
  alias Milk.Log.NotificationLog

  def create(conn, %{"notif" => notif}) do
    {:ok, notif} = Notif.create_notification_log(notif)

    render(conn, "show.json", notif: notif)
  end
end
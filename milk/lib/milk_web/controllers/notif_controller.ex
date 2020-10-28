defmodule MilkWeb.NotifController do
  use MilkWeb, :controller

  alias Milk.Notif
  alias Milk.Notif.Notification

  def get_list(conn, %{"notif" => notif}) do
    notifs = Notif.list_notification(notif["user_id"])
    render(conn, "list.json", notif: notifs)
  end

  def create(conn, %{"notif" => notif}) do
    {:ok,notif} = Notif.create_notification(notif)
    render(conn,"show.json",notif: notif)
  end

  def delete(conn, %{"id" => id}) do
    notif = Notif.get_notification!(id)
    with {:ok, %Notification{}} <- Notif.delete_notification(notif) do
      send_resp(conn, :no_content, "")
    end
  end
end
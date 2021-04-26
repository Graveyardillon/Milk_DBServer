defmodule MilkWeb.NotifController do
  use MilkWeb, :controller

  alias Milk.{
    Accounts,
    Notif
  }
  alias Milk.Notif.Notification

  def get_list(conn, %{"user_id" => user_id}) do
    notifs = Notif.list_notification(user_id)
    render(conn, "list.json", notif: notifs)
  end

  def create(conn, %{"notif" => notif}) do
    {:ok, notif} = Notif.create_notification(notif)

    render(conn, "show.json", notif: notif)
  end

  def delete(conn, %{"id" => id}) do
    notif = Notif.get_notification!(id)
    with {:ok, %Notification{}} <- Notif.delete_notification(notif) do
      json(conn, %{result: true})
    end
  end

  # FIXME: 権限の認証をつけるべき
  def notify_all(conn, %{"text" => text}) do
    Accounts.list_user()
    |> Enum.each(fn user ->
      %{}
      |> Map.put("user_id", user.id)
      |> Map.put("content", text)
      |> Map.put("process_code", 0)
      |> Map.put("data", "")
      |> Notif.create_notification()
    end)

    json(conn, %{result: true})
  end
end

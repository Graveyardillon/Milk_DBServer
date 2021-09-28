defmodule MilkWeb.NotifController do
  use MilkWeb, :controller

  alias Common.Tools
  alias Maps

  alias Milk.{
    Accounts,
    Notif
  }

  alias Milk.Notif.Notification

  def get_list(conn, %{"user_id" => user_id}) do
    user_id = Tools.to_integer_as_needed(user_id)

    notifs = Notif.list_notification(user_id)

    render(conn, "list.json", notif: notifs)
  end

  def create(conn, %{"notif" => notif}) do
    {:ok, notif} = Notif.create_notification(notif)
    notif = Map.put(notif, :icon, nil)

    render(conn, "show.json", notif: notif)
  end

  def delete(conn, %{"id" => id}) do
    id = Tools.to_integer_as_needed(id)

    notif = Notif.get_notification!(id)

    with {:ok, %Notification{}} <- Notif.delete_notification(notif) do
      json(conn, %{result: true})
    else
      _ -> json(conn, %{result: false})
    end
  end

  # FIXME: 権限の認証をつけるべき 引数にbody_textの追加
  def notify_all(conn, %{"text" => title}) do
    Accounts.list_user()
    |> Enum.each(fn user ->
      Map.new()
      |> Map.put("user_id", user.id)
      |> Map.put("title", title)
      # |> Map.put("body_text", body_text)
      |> Map.put("process_id", "COMMON")
      # |> Map.put("data", "")
      |> Notif.create_notification()
    end)

    json(conn, %{result: true})
  end

  def check_all(conn, %{"user_id" => user_id}) do
    user_id
    |> Tools.to_integer_as_needed()
    |> Notif.unchecked_notifications()
    |> Enum.each(fn notification ->
      Notif.update_notification(notification, %{is_checked: true})
    end)

    json(conn, %{result: true})
  end

  def test_push_notice(conn, %{"token" => token}) do
    params = %{"tournament_id" => 1}

    %Maps.PushIos{
      user_id: 1,
      device_token: token,
      process_id: "COMMON",
      title: "test notice",
      message: "test noticeeeee",
      params: params
    }
    |> Milk.Notif.push_ios()

    json(conn, %{result: "ok"})
  end
end

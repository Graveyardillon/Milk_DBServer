defmodule MilkWeb.NotifController do
  use MilkWeb, :controller

  alias Common.Tools

  alias Milk.{
    Accounts,
    Notif
  }
  alias Milk.CloudStorage.Objects
  alias Milk.Media.Image
  alias Milk.Notif.Notification

  def get_list(conn, %{"user_id" => user_id}) do
    user_id = Tools.to_integer_as_needed(user_id)

    notifs = user_id
      |> Notif.list_notification()
      |> Enum.map(fn notification ->
        if is_nil(notification.icon_path) do
          Map.put(notification, :icon, nil)
        else
          icon = notification.process_code
          |> case do
            1 -> read_icon(notification.icon_path)
            4 -> read_icon(notification.icon_path)
            5 -> read_icon(notification.icon_path)
            6 -> read_thumbnail(notification.icon_path)
            _ -> nil
          end

          Map.put(notification, :icon, icon)
        end
      end)
      |> IO.inspect(label: :asdf)

    render(conn, "list.json", notif: notifs)
  end

  defp read_icon(path) do
    :milk
    |> Application.get_env(:environment)
    |> case do
      :dev -> read_icon_dev(path)
      :test -> read_icon_dev(path)
      _ -> read_icon_prod(path)
    end
    |> IO.inspect(label: :icon)
  end

  defp read_icon_dev(path) do
    File.read(path)
  end

  defp read_icon_prod(name) do
    name
    |> Objects.get()
    |> Map.get(:mediaLink)
    |> Image.get()
  end

  defp read_thumbnail(name) do
    :milk
    |> Application.get_env(:environment)
    |> case do
      :dev -> read_thumbnail_dev(name)
      :test -> read_thumbnail_dev(name)
      _ -> read_thumbnail_prod(name)
    end
    |> case do
      %{b64: b64} -> b64
      %{error: _} -> nil
    end
  end

  defp read_thumbnail_dev(name) do
    File.read("./static/image/tournament_thumbnail/#{name}.jpg")
    |> case do
      {:ok, file} ->
        b64 = Base.encode64(file)
        %{b64: b64}

      {:error, _} ->
        %{error: "image not found"}
    end
  end

  defp read_thumbnail_prod(name) do
    name
    |> Objects.get()
    |> Map.get(:mediaLink)
    |> Image.get()
    |> case do
      {:ok, file} ->
        b64 = Base.encode64(file)
        %{b64: b64}
      _ ->
        %{error: "image not found"}
    end
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

  # FIXME: 権限の認証をつけるべき
  def notify_all(conn, %{"text" => text}) do
    Accounts.list_user()
    |> Enum.each(fn user ->
      Map.new()
      |> Map.put("user_id", user.id)
      |> Map.put("content", text)
      |> Map.put("process_code", 0)
      |> Map.put("data", "")
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
end

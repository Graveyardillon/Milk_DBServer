defmodule MilkWeb.CheckController do
  use MilkWeb, :controller

  import Common.Sperm

  alias Common.Tools
  alias Milk.Notif

  @doc """
  Check if server is available.
  """
  def connection_check(conn, _params) do
    json(conn, %{result: true})
  end

  @doc """
  Check some data for web.
  NOTE: web版用
  """
  def data_for_web(conn, %{"user_id" => user_id}) do
    user_id
    |> Tools.to_integer_as_needed()
    |> Notif.count_unchecked_notifications()
    |> IO.inspect(label: :unchecked_notifications_count)
    |> unchecked_notifications_exist?()
    ~> unchecked_notifcations_exist?

    render(conn, "check_for_web.json", unchecked_notification_exists: unchecked_notifcations_exist?)
  end

  defp unchecked_notifications_exist?(0), do: false
  defp unchecked_notifications_exist?(_), do: true
end

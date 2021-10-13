defmodule MilkWeb.DeviceController do
  use MilkWeb, :controller

  alias Common.Tools
  alias Milk.Accounts

  def register_token(conn, %{"user_id" => user_id, "device_id" => token}) do
    user_id = Tools.to_integer_as_needed(user_id)
    token = to_string(token)

    case Accounts.get_device(token) do
      nil ->
        Accounts.register_device(user_id, token)
        |> case do
          {:ok, device} -> render(conn, "show.json", device: device)
          {:error, error} -> render(conn, "error.json", error: error)
        end

      device ->
        render(conn, "show.json", device: device)
    end
  end

  def unregister_token(conn, %{"device_id" => token}) do
    token
    |> Accounts.get_device()
    |> Accounts.unregister_device()
    |> case do
      {:ok, _} -> json(conn, %{result: true})
      {:error, _} -> json(conn, result: false)
    end
  end
end

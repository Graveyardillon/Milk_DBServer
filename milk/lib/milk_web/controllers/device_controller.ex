defmodule MilkWeb.DeviceController do
  use MilkWeb, :controller

  alias Common.Tools
  alias Milk.Accounts

  def register_token(conn, %{"user_id" => user_id, "device_id" => token}) do
    user_id = Tools.to_integer_as_needed(user_id)

    %{"user_id" => user_id, "device_id" => token}
    |> Accounts.register_device()
    |> case do
      {:ok, device} -> render(conn, "show.json", device: device)
      {:error, error} -> render(conn, "error.json", error: error)
    end
  end
end

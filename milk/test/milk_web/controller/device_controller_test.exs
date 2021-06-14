defmodule MilkWeb.DeviceControllerTest do
  use MilkWeb.ConnCase

  alias Milk.Accounts

  defp fixture_user(n \\ 0) do
    attrs = %{
      "icon_path" => "some icon_path",
      "language" => "some language",
      "name" => to_string(n) <> "some name",
      "notification_number" => 42,
      "point" => 42,
      "email" => to_string(n) <> "some@email.com",
      "logout_fl" => true,
      "password" => "S1ome password"
    }

    {:ok, user} = Accounts.create_user(attrs)
    Accounts.get_user(user.id)
  end

  describe "register device" do
    test "works", %{conn: conn} do
      user = fixture_user()
      token = "something"

      conn = post(conn, Routes.device_path(conn, :register_token), %{user_id: user.id, device_id: token})
      json_response(conn, 200)
      |> Map.get("result")
      |> assert()

      json_response(conn, 200)
      |> Map.get("data")
      |> (fn device ->
        assert device["token"] == token
        assert device["user_id"] == user.id
      end).()
    end

    test "invalid user id", %{conn: conn} do
      token = "invaliduserid"

      conn = post(conn, Routes.device_path(conn, :register_token), %{user_id: 0, device_id: token})
      json_response(conn, 200)
      |> IO.inspect()
    end
  end
end

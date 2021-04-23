defmodule MilkWeb.NotifControllerTest do
  use MilkWeb.ConnCase

  alias Milk.Accounts

  @create_user_attrs %{"icon_path" => "some icon_path", "language" => "some language", "name" => "some name", "notification_number" => 42, "point" => 42, "email" => "some2@email.com", "logout_fl" => true, "password" => "S1ome password"}

  defp fixture_user() do
    Accounts.create_user(@create_user_attrs)
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "get list" do

  end

  describe "create" do

  end
end

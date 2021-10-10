defmodule MilkWeb.CheckControllerTest do
  use MilkWeb.ConnCase

  use Common.Fixtures

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "connection check" do
    test "works", %{conn: conn} do
      conn = get(conn, Routes.check_path(conn, :connection_check))
      assert json_response(conn, 200)["result"]
    end
  end

  describe "check data for web" do
    test "works", %{conn: conn} do
      user = fixture_user()
      conn = post(conn, Routes.check_path(conn, :data_for_web), %{user_id: user.id})

      assert json_response(conn, 200)["result"]
      refute json_response(conn, 200)["unchecked_notification_exists"]
    end
  end
end

defmodule MilkWeb.ConnectionCheckControllerTest do
  use MilkWeb.ConnCase

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "connection check" do
    test "works", %{conn: conn} do
      conn = get(conn, Routes.connection_check_path(conn, :connection_check))
      assert json_response(conn, 200)["result"]
    end
  end
end

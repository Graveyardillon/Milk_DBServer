defmodule MilkWeb.ReportControllerTest do
  use MilkWeb.ConnCase

  alias Milk.Accounts

  defp fixture_user(n \\ 0) do
    attrs = %{"icon_path" => "some icon_path", "language" => "some language", "name" => to_string(n)<>"some name", "notification_number" => 42, "point" => 42, "email" => to_string(n)<>"some@email.com", "logout_fl" => true, "password" => "S1ome password"}
    {:ok, user} = Accounts.create_user(attrs)
    user
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create user report" do
    test "works", %{conn: conn} do
      reporter = fixture_user(1)
      reportee = fixture_user(2)

      conn = post(conn, Routes.report_path(conn, :create_user_report), report: %{reporter: reporter.id, reportee: reportee.id, report_types: [0]})
      assert json_response(conn, 200)["result"]
    end
  end
end

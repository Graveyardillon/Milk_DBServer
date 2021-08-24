defmodule MilkWeb.ExternalServiceControllerTest do
  use MilkWeb.ConnCase
  use Common.Fixtures

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create external service" do
    test "works", %{conn: conn} do
      user = fixture_user()

      conn = post(conn, Routes.external_service_path(conn, :create), user_id: user.id, name: "twitter", content: "@papillo333")
      response = json_response(conn, 200)
      assert response["result"]
      refute is_nil(response["data"]["id"])
      assert response["data"]["name"] == "twitter"
      assert response["data"]["content"] == "@papillo333"
    end
  end
end

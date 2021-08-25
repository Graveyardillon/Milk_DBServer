defmodule MilkWeb.ExternalServiceControllerTest do
  use MilkWeb.ConnCase
  use Common.Fixtures

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create external service" do
    test "works", %{conn: conn} do
      user = fixture_user()

      conn =
        post(conn, Routes.external_service_path(conn, :create),
          user_id: user.id,
          name: "twitter",
          content: "@papillo333"
        )

      response = json_response(conn, 200)
      assert response["result"]
      refute is_nil(response["data"]["id"])
      assert response["data"]["name"] == "twitter"
      assert response["data"]["content"] == "@papillo333"

      id = response["data"]["id"]

      conn = get(conn, Routes.profile_path(conn, :external_services), user_id: user.id)

      conn
      |> json_response(200)
      |> Map.get("data")
      |> length()
      |> Kernel.==(1)
      |> assert()

      conn =
        delete(conn, Routes.external_service_path(conn, :delete),
          id: id
        )

      response = json_response(conn, 200)
      assert response["result"]
      assert response["data"]["id"] == id

      conn = get(conn, Routes.profile_path(conn, :external_services), user_id: user.id)

      conn
      |> json_response(200)
      |> Map.get("data")
      |> length()
      |> Kernel.==(0)
      |> assert()
    end
  end
end

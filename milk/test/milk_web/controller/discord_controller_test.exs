defmodule MilkWeb.DiscordControllerTest do
  use MilkWeb.ConnCase
  use Common.Fixtures

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "associate and dissociate" do
    test "already associated and then dissociate", %{conn: conn} do
      discord_user = fixture_discord_user()

      conn =
        post(conn, Routes.discord_path(conn, :associate), %{
          user_id: discord_user.user_id,
          discord_id: discord_user.discord_id
        })

      refute json_response(conn, 200)["result"]
      assert is_nil(json_response(conn, 200)["data"])
      assert json_response(conn, 200)["error"] == "already associated"

      conn = delete(conn, Routes.discord_path(conn, :dissociate), %{user_id: discord_user.user_id})

      assert json_response(conn, 200)["result"]
    end
  end
end

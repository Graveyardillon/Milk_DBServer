defmodule MilkWeb.BracketControllerTest do
  @moduledoc """
  bracket controllerに関するテスト
  """
  use MilkWeb.ConnCase
  use Common.Fixtures

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create bracket" do
    test "works", %{conn: conn} do
      user = fixture_user()

      params = %{
        "name" => "test brackets",
        "owner_id" => user.id,
        "url" => "test url",
        "enabled_bronze_medal_match" => false
      }

      conn = post(conn, Routes.bracket_path(conn, :create_bracket), %{"brackets" => params})
      assert json_response(conn, 200)["result"]

      assert json_response(conn, 200)["data"]["name"] === params["name"]
      assert json_response(conn, 200)["data"]["owner_id"] === params["owner_id"]
      assert json_response(conn, 200)["data"]["url"] === params["url"]
      assert json_response(conn, 200)["data"]["enabled_bronze_medal_match"] === params["enabled_bronze_medal_match"]
    end
  end
end

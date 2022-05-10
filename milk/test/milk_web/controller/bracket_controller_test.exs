defmodule MilkWeb.BracketControllerTest do
  @moduledoc """
  bracket controllerに関するテスト
  """
  use MilkWeb.ConnCase
  use Common.Fixtures

  alias Milk.Brackets

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  defp fixture_bracket() do
    user = fixture_user()

    %{name: "test", owner_id: user.id, url: "test"}
    |> Brackets.create_bracket()
    |> elem(1)
  end

  describe "create bracket" do
    test "works", %{conn: conn} do
      user = fixture_user()

      params = %{
        "name" => "test brackets",
        "owner_id" => user.id,
        "rule" => "basic",
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

  describe "is url valid" do
    test "works", %{conn: conn} do
      bracket = fixture_bracket()

      conn = get(conn, Routes.bracket_path(conn, :is_url_valid), %{url: bracket.url})
      refute json_response(conn, 200)["result"]

      conn = get(conn, Routes.bracket_path(conn, :is_url_valid), %{url: "WORKS"})
      assert json_response(conn, 200)["result"]
    end
  end

  describe "get bracket" do
    test "works", %{conn: conn} do
      bracket = fixture_bracket()

      conn = get(conn, Routes.bracket_path(conn, :get_bracket), bracket_id: bracket.id)

      assert json_response(conn, 200)["data"]["name"] === bracket.name
      assert json_response(conn, 200)["data"]["owner_id"] === bracket.owner_id
      assert json_response(conn, 200)["data"]["url"] === bracket.url
      assert json_response(conn, 200)["data"]["enabled_bronze_medal_match"] === bracket.enabled_bronze_medal_match
    end
  end

  describe "get brackets by owner id" do
    test "works", %{conn: conn} do
      user = fixture_user()

      params = %{
        "name" => "test brackets",
        "owner_id" => user.id,
        "rule" => "basic",
        "url" => "test url",
        "enabled_bronze_medal_match" => false
      }

      conn = post(conn, Routes.bracket_path(conn, :create_bracket), %{"brackets" => params})
      conn = post(conn, Routes.bracket_path(conn, :create_bracket), %{"brackets" => params})
      conn = post(conn, Routes.bracket_path(conn, :create_bracket), %{"brackets" => params})
      conn = post(conn, Routes.bracket_path(conn, :create_bracket), %{"brackets" => params})
      conn = post(conn, Routes.bracket_path(conn, :create_bracket), %{"brackets" => params})

      conn = get(conn, Routes.bracket_path(conn, :get_brackets_by_owner_id), %{"owner_id" => user.id})

      conn
      |> json_response(200)
      |> Map.get("data")
      |> Enum.map(fn bracket ->
        assert bracket["name"] === params["name"]
        assert bracket["owner_id"] === params["owner_id"]
        assert bracket["rule"] === params["rule"]
        assert bracket["url"] === params["url"]
        assert bracket["enabled_bronze_medal_match"] === params["enabled_bronze_medal_match"]
      end)
      |> length()
      |> Kernel.==(5)
    end
  end
end

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

      1..5
      |> Enum.to_list()
      |> Enum.each(fn n ->
        params = %{
          "name" => "test brackets",
          "owner_id" => user.id,
          "rule" => "basic",
          "url" => "test url #{n}",
          "enabled_bronze_medal_match" => false
        }

        post(conn, Routes.bracket_path(conn, :create_bracket), %{"brackets" => params})
      end)

      conn = get(conn, Routes.bracket_path(conn, :get_brackets_by_owner_id), %{"owner_id" => user.id})

      conn
      |> json_response(200)
      |> Map.get("data")
      |> length()
      |> Kernel.==(5)
      |> assert()
    end
  end

  describe "create participants" do
    test "works", %{conn: conn} do
      bracket = fixture_bracket()

      names = [
        "test1user",
        "test2user",
        "test3user",
        "test4user"
      ]
      conn = post(conn, Routes.bracket_path(conn, :create_participants), %{"names" => names, "bracket_id" => bracket.id})

      assert json_response(conn, 200)["result"]

      conn = get(conn, Routes.bracket_path(conn, :get_participants), bracket_id: bracket.id)

      conn
      |> json_response(200)
      |> Map.get("data")
      |> length()
      |> Kernel.==(4)
      |> assert()

      bracket = Brackets.get_bracket(bracket.id)

      refute is_nil(bracket.match_list_str)
      refute is_nil(bracket.match_list_with_fight_result_str)

      match_list_str = bracket.match_list_str
      match_list_with_fight_result_str = bracket.match_list_with_fight_result_str

      new_names = [
        "test5user",
        "test6user"
      ]

      conn = post(conn, Routes.bracket_path(conn, :create_participants), %{"names" => new_names, "bracket_id" => bracket.id})

      assert json_response(conn, 200)["result"]

      conn = get(conn, Routes.bracket_path(conn, :get_participants), bracket_id: bracket.id)

      conn
      |> json_response(200)
      |> Map.get("data")
      |> length()
      |> Kernel.==(6)
      |> assert()

      bracket = Brackets.get_bracket(bracket.id)

      assert String.length(match_list_str) < String.length(bracket.match_list_str)
      assert String.length(match_list_with_fight_result_str) < String.length(bracket.match_list_with_fight_result_str)
    end
  end

  describe "get brackets for draw" do
    test "works", %{conn: conn} do
      bracket = fixture_bracket()

      names = [
        "test1user",
        "test2user",
        "test3user",
        "test4user"
      ]
      conn = post(conn, Routes.bracket_path(conn, :create_participants), %{"names" => names, "bracket_id" => bracket.id})

      conn = get(conn, Routes.bracket_path(conn, :get_brackets_for_draw), %{"bracket_id" => bracket.id})

      conn
      |> json_response(200)
      |> Map.get("data")
      |> is_list()
      |> assert()
    end
  end

  describe "edit brackets" do
    test "works", %{conn: conn} do
      bracket = fixture_bracket()

      names = [
        "test1user",
        "test2user",
        "test3user",
        "test4user"
      ]
      conn = post(conn, Routes.bracket_path(conn, :create_participants), %{"names" => names, "bracket_id" => bracket.id})

      conn = get(conn, Routes.bracket_path(conn, :get_brackets_for_draw), %{"bracket_id" => bracket.id})

      conn
      |> json_response(200)
      |> Map.get("data")
      |> List.flatten()
      |> Enum.map(&(&1["name"]))
      |> then(fn list ->
        assert list == Enum.reverse(names)
      end)
    end
  end

  describe "start" do
    test "works", %{conn: conn} do
      bracket = fixture_bracket()

      names = [
        "test1user",
        "test2user",
        "test3user",
        "test4user"
      ]
      conn = post(conn, Routes.bracket_path(conn, :create_participants), %{"names" => names, "bracket_id" => bracket.id})

      conn = post(conn, Routes.bracket_path(conn, :start), bracket_id: bracket.id)

      bracket = Brackets.get_bracket(bracket.id)

      assert bracket.is_started
    end
  end

  describe "undo start" do
    test "works", %{conn: conn} do
      bracket = fixture_bracket()

      names = [
        "test1user",
        "test2user",
        "test3user",
        "test4user"
      ]
      conn = post(conn, Routes.bracket_path(conn, :create_participants), %{"names" => names, "bracket_id" => bracket.id})

      conn = post(conn, Routes.bracket_path(conn, :start), bracket_id: bracket.id)
      conn = post(conn, Routes.bracket_path(conn, :undo_start), bracket_id: bracket.id)

      bracket = Brackets.get_bracket(bracket.id)

      refute bracket.is_started
    end
  end
end

defmodule MilkWeb.ProfileControllerTest do
  use MilkWeb.ConnCase
  use Common.Fixtures

  alias Milk.{
    Accounts,
    Tournaments
  }

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "profile" do

    test "get profile", %{conn: conn} do
      user = fixture_user()

      profile = conn
      |> get(Routes.profile_path(conn, :get_profile), user_id: user.id)
      |> json_response(200)
      |> Map.get("data")

      assert profile["name"] == "name0"
    end

    test "update profile", %{conn: conn} do
      user = fixture_user()

      update_attrs = %{
          "user_id" => user.id,
          "name" => user.name <> "updated",
          "bio" => "updated bio",
          "birthday" => DateTime.utc_now(),
          "is_birthday_private" => false,
          "records" => []
      }

      result =
      conn
      |> post(Routes.profile_path(conn, :update), profile: update_attrs)
      |> json_response(200)
      |> Map.get("result")
      assert result == true

      updated_profile =
      conn
      |> get(Routes.profile_path(conn, :get_profile), user_id: user.id)
      |> json_response(200)
      |> Map.get("data")

      assert updated_profile["name"] == update_attrs["name"]
      assert updated_profile["bio"] == update_attrs["bio"]
      assert updated_profile["records"] == update_attrs["records"]
      assert updated_profile["is_birthday_private"] == update_attrs["is_birthday_private"]
    end


    test "records of profile", %{conn: conn} do
      user = fixture_user()

      tournament = fixture_tournament(master_id: user.id)

      %{"tournament_id" => tournament.id, "user_id" => user.id, "rank" => 5}
      |> Tournaments.create_entrant()

      setup_tournament_having_participants(tournament.id)
      Tournaments.start(user.id, tournament.id)
      Tournaments.finish(tournament.id, user.id)

      get(conn, Routes.profile_path(conn, :records), %{"user_id" => user.id})
      |> json_response(200)
      |> Map.get("data")
      |> Enum.map(fn record ->
        assert record["rank"] == 5
        assert record["tournament"]["master_id"] == user.id
      end)
    end

    defp setup_tournament_having_participants(tournament_id) do
      1..7
      |> Enum.map(fn n ->
        fixture_user(num: n)
      end)
      |> Enum.map(fn user ->
        %{"tournament_id" => tournament_id, "user_id" => user.id, "rank" => 42}
        |> Tournaments.create_entrant()
      end)
    end

    test "external services", %{conn: conn} do
      user = fixture_user()

      name = "twitter"
      content = "@apillo23"

      Map.new()
      |> Map.put(:name, name)
      |> Map.put(:content, content)
      |> Map.put(:user_id, user.id)
      |> Accounts.create_external_service()

      conn
      |> get(Routes.profile_path(conn, :external_services), user_id: user.id)
      |> json_response(200)
      |> Map.get("data")
      |> Enum.map(fn external_service ->
        assert external_service["name"] == name
        assert external_service["content"] == content
        refute is_nil(external_service["id"])
      end)
      |> length()
      |> Kernel.==(1)
      |> assert()
    end
  end
end

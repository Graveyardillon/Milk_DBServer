defmodule MilkWeb.ProfileControllerTest do
  use MilkWeb.ConnCase
  use Common.Fixtures

  alias Milk.{
    Accounts,
    Profiles,
    Tournaments
  }

  alias Milk.Accounts.Profile

  @create_attrs %{
    "name" => "some name",
    "content_id" => "42",
    "content_type" => "42",
    "bio" => "some bio",
    "gameList" => [],
    "records" => []
  }

  @update_attrs %{
    "name" => "some name",
    "content_id" => "42",
    "content_type" => "42",
    "bio" => "some bio",
    "gameList" => [],
    "records" => []
  }

  def fixture(:profile) do
    user = fixture_user()

    {:ok, profile} =
      @create_attrs
      |> Map.put("user_id", user.id)
      |> Profiles.create_profile()

    profile
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "update profile" do
    setup [:create_profile]

    test "renders profile when data is valid", %{conn: conn, profile: %Profile{id: _id} = profile} do
      attrs = Map.put(@update_attrs, "user_id", profile.user_id)
      conn = post(conn, Routes.profile_path(conn, :update), profile: attrs)
      assert json_response(conn, 200)["result"]

      conn = post(conn, Routes.profile_path(conn, :get_profile), user_id: profile.user_id)

      assert %{"id" => id} = json_response(conn, 200)["data"]
    end
  end

  describe "records of profile" do
    setup [:create_profile]

    test "renders records when data is valid", %{conn: conn, profile: profile} do
      user_id = profile.user_id

      tournament = fixture_tournament(master_id: user_id)

      %{"tournament_id" => tournament.id, "user_id" => user_id, "rank" => 5}
      |> Tournaments.create_entrant()

      setup_tournament_having_participants(tournament.id)
      Tournaments.start(user_id, tournament.id)
      Tournaments.finish(tournament.id, user_id)

      get(conn, Routes.profile_path(conn, :records), %{"user_id" => user_id})
      |> json_response(200)
      |> Map.get("data")
      |> length()
      |> (fn records_length ->
            assert records_length == 1
          end).()
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
  end

  describe "external service" do
    test "work", %{conn: conn} do
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

  defp create_profile(_) do
    profile = fixture(:profile)
    %{profile: profile}
  end
end

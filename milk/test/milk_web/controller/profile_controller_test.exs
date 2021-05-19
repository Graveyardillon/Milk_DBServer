defmodule MilkWeb.ProfileControllerTest do
  use MilkWeb.ConnCase

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
  @tournament_attrs %{
    "capacity" => 42,
    "deadline" => "2010-04-17T14:00:00Z",
    "description" => "some description",
    "event_date" => "2010-04-17T14:00:00Z",
    "name" => "some name",
    "type" => 0,
    "url" => "somesomeurl",
    "master_id" => 1,
    "platform" => 1,
    "is_started" => true
  }

  def fixture(:profile) do
    user = fixture_user()

    {:ok, profile} =
      @create_attrs
      |> Map.put("user_id", user.id)
      |> Profiles.create_profile()

    profile
  end

  def fixture_user(opts \\ []) do
    num_str =
      opts[:num]
      |> is_nil()
      |> unless do
        to_string(opts[:num])
      else
        "-1"
      end

    attrs = %{
      "icon_path" => "some icon_path",
      "language" => "some language",
      "name" => "some name" <> num_str,
      "notification_number" => 42,
      "point" => 42,
      "password" => "Password123",
      "email" => "e@mail.com" <> num_str
    }

    {:ok, user} = Accounts.create_user(attrs)
    user
  end
  # defp fixture_tournament(opts \\ []) do
  defp fixture_tournament(opts) do
    master_id =
      opts[:master_id]
      |> is_nil()
      |> unless do
        opts[:master_id]
      else
        {:ok, user} =
          Accounts.create_user(%{
            "name" => "name",
            "email" => "e@mail.com",
            "password" => "Password123"
          })

        user.id
      end

    {:ok, tournament} =
      @tournament_attrs
      |> Map.put("is_started", false)
      |> Map.put("master_id", master_id)
      |> Tournaments.create_tournament()

    tournament
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

  defp create_profile(_) do
    profile = fixture(:profile)
    %{profile: profile}
  end
end

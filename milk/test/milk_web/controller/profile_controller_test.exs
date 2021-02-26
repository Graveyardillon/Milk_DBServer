defmodule MilkWeb.ProfileControllerTest do
  use MilkWeb.ConnCase

  alias Milk.Accounts
  alias Milk.Profiles
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
  @invalid_attrs %{content_id: nil, content_type: nil, user_id: nil}

  def fixture(:profile) do
    user = fixture(:user)
    {:ok, profile} =
      @create_attrs
      |> Map.put("user_id", user.id)
      |> Profiles.create_profile()
    profile
  end

  def fixture(:user) do
    attrs = %{
      "icon_path"  => "some icon_path",
      "language" => "some language",
      "name" => "some name",
      "notification_number" => 42,
      "point" => 42,
      "password" => "Password123",
      "email" => "e@mail.com"
    }
    {:ok, user} = Accounts.create_user(attrs)
    user
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "update profile" do
    setup [:create_profile]

    test "renders profile when data is valid", %{conn: conn, profile: %Profile{id: id} = profile} do
      attrs = Map.put(@update_attrs, "user_id", profile.user_id)
      conn = post(conn, Routes.profile_path(conn, :update), profile: attrs)
      assert json_response(conn, 200)["result"]

      conn = post(conn, Routes.profile_path(conn, :get_profile), user_id: profile.user_id)

      assert %{"id" => id} = json_response(conn, 200)["data"]
    end
  end

  defp create_profile(_) do
    profile = fixture(:profile)
    %{profile: profile}
  end
end

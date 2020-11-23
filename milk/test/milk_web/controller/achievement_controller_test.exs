defmodule MilkWeb.AchievementControllerTest do
  use MilkWeb.ConnCase

  alias Milk.Achievements
  alias Milk.Accounts
  alias Milk.Achievements.Achievement

  @create_attrs %{
    icon_path: "some icon_path",
    title: "some title",
    user_id: "some user_id"
  }
  @update_attrs %{
    icon_path: "some updated icon_path",
    title: "some updated title",
    user_id: "some updated user_id"
  }
  @invalid_attrs %{icon_path: nil, title: nil, user_id: nil}

  @user_valid_attrs %{"icon_path" => "some icon_path", "language" => "some language", "name" => "some name", "notification_number" => 42, "point" => 42, "email" => "some@email.com", "logout_fl" => true, "password" => "S1ome password"}
  def fixture(:achievement) do
    {:ok, user} = Accounts.create_user(@user_valid_attrs)
    {:ok, achievement} = Achievements.create_achievement(%{@create_attrs| user_id: user.id})
    achievement
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all achievements", %{conn: conn} do
      conn = get(conn, Routes.achievement_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create achievement" do
    test "renders achievement when data is valid", %{conn: conn} do
      {:ok, user} = Accounts.create_user(@user_valid_attrs)
      conn = post(conn, Routes.achievement_path(conn, :create), achievement: %{@create_attrs|user_id: user.id})
      assert %{"id" => id} = json_response(conn, 200)["data"]

      conn = post(conn, Routes.achievement_path(conn, :show_one), id: id)
      user_id = user.id
      assert %{
               "id" => id,
               "icon_path" => "some icon_path",
               "title" => "some title",
               "user_id" => user_id
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.achievement_path(conn, :create), achievement: @invalid_attrs)
      assert json_response(conn, 200)["errors"] != %{}
    end
  end

  describe "update achievement" do
    setup [:create_achievement]

    test "renders achievement when data is valid", %{conn: conn, achievement: %Achievement{id: id} = achievement} do
      conn = post(conn, Routes.achievement_path(conn, :update), id: achievement.id, attrs: %{@update_attrs|user_id: achievement.user_id})
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = post(conn, Routes.achievement_path(conn, :show_one), id: id)
      user_id = achievement.user_id
      assert %{
               "id" => id,
               "icon_path" => "some updated icon_path",
               "title" => "some updated title",
               "user_id" => user_id
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, achievement: achievement} do
      conn = post(conn, Routes.achievement_path(conn, :update), id: achievement.id, attrs: @invalid_attrs)
      assert json_response(conn, 200)["errors"] != %{}
    end
  end

  describe "delete achievement" do
    setup [:create_achievement]

    test "deletes chosen achievement", %{conn: conn, achievement: achievement} do
      conn = delete(conn, Routes.achievement_path(conn, :delete), achievement)
      assert response(conn, 200)
      |> Poison.decode!()
      |> Map.get("data") ==
        %{
          "title" => achievement.title,
          "id" => achievement.id,
          "user_id" => achievement.user_id
        }
    end
  end

  defp create_achievement(_) do
    achievement = fixture(:achievement)
    %{achievement: achievement}
  end
end

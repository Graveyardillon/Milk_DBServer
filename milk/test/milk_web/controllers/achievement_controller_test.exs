defmodule MilkWeb.AchievementControllerTest do
  use MilkWeb.ConnCase

  alias Milk.Achievements
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

  def fixture(:achievement) do
    {:ok, achievement} = Achievements.create_achievement(@create_attrs)
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
      conn = post(conn, Routes.achievement_path(conn, :create), achievement: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.achievement_path(conn, :show, id))

      assert %{
               "id" => id,
               "icon_path" => "some icon_path",
               "title" => "some title",
               "user_id" => "some user_id"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.achievement_path(conn, :create), achievement: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update achievement" do
    setup [:create_achievement]

    test "renders achievement when data is valid", %{conn: conn, achievement: %Achievement{id: id} = achievement} do
      conn = put(conn, Routes.achievement_path(conn, :update, achievement), achievement: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.achievement_path(conn, :show, id))

      assert %{
               "id" => id,
               "icon_path" => "some updated icon_path",
               "title" => "some updated title",
               "user_id" => "some updated user_id"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, achievement: achievement} do
      conn = put(conn, Routes.achievement_path(conn, :update, achievement), achievement: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete achievement" do
    setup [:create_achievement]

    test "deletes chosen achievement", %{conn: conn, achievement: achievement} do
      conn = delete(conn, Routes.achievement_path(conn, :delete, achievement))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.achievement_path(conn, :show, achievement))
      end
    end
  end

  defp create_achievement(_) do
    achievement = fixture(:achievement)
    %{achievement: achievement}
  end
end

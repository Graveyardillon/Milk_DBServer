defmodule MilkWeb.UserControllerTest do
  use MilkWeb.ConnCase

  alias Milk.Accounts
  alias Milk.Accounts.User

  @create_attrs %{
    "icon_path"  => "some icon_path",
    "language" => "some language",
    "name" => "some name",
    "notification_number" => 42,
    "point" => 42,
    "password" => "Password123",
    "email" => "e@mail.com"
  }
  @update_attrs %{
    icon_path: "some updated icon_path",
    language: "some updated language",
    name: "some updated name",
    notification_number: 43,
    point: 43
  }
  @invalid_attrs %{icon_path: nil, language: nil, name: nil, notification_number: nil, point: nil}

  def fixture(:user) do
    {:ok, user} = Accounts.create_user(@create_attrs)
    user
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all users", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :index))
      assert json_response(conn, 200)["data"] == nil
    end
  end

  describe "create user" do
    test "renders user when data is valid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @create_attrs)
      assert %{"id" => id} = json_response(conn, 200)["data"]

      conn = post(conn, Routes.user_path(conn, :show), id: id)

      assert %{
               "id" => id,
               "icon_path" => "some icon_path",
               "language" => "some language",
               "name" => "some name",
               "notification_number" => 42,
               "point" => 42
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when email has already been taken", %{conn: conn} do
      {:ok, user} = Accounts.create_user(%{"name" => "name", "email" => "e@mail.com", "password" => "Password123"})
      attrs = %{@create_attrs | "email" => user.auth.email}
      conn = post(conn, Routes.user_path(conn, :create), user: attrs)
      assert json_response(conn, 200)["error_code"] == 101
    end

    test "renders errors when password is too short", %{conn: conn} do
      attrs = %{@create_attrs | "password" => "Ab123"}
      conn = post(conn, Routes.user_path(conn, :create), user: attrs)
      assert json_response(conn, 200)["error_code"] == 102
    end

    test "renders errors when password is invalid constraint", %{conn: conn} do
      attrs = %{@create_attrs | "password" => "AAAAAAAAA"}
      conn = post(conn, Routes.user_path(conn, :create), user: attrs)
      assert json_response(conn, 200)["error_code"] == 103
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @invalid_attrs)
      assert json_response(conn, 200)["errors"] != %{}
    end
  end
  describe "login user" do
    test "renders error when invalid email", %{conn: conn} do
      {:ok, user} = Accounts.create_user(%{"name" => "name", "email" => "e@mail.com", "password" => "Password123", "logout_fl" => true})
      conn = post(conn, Routes.user_path(conn, :login), user: %{"email_or_username" => "ew@mail.com", "password" => "Password123"})
      assert assert json_response(conn, 200)["error_code"] == 104
    end
    test "renders error when invalid password", %{conn: conn} do
      {:ok, user} = Accounts.create_user(%{"name" => "name", "email" => "e@mail.com", "password" => "Password123", "logout_fl" => true})
      conn = post(conn, Routes.user_path(conn, :login), user: %{"email_or_username" => "e@mail.com", "password" => "Password1234z"})
      assert assert json_response(conn, 200)["error_code"] == 104
    end
  end
  # describe "update user" do
  #   setup [:create_user]

  #   test "renders user when data is valid", %{conn: conn, user: %User{id: id} = user} do
  #     conn = put(conn, Routes.user_path(conn, :update, user), user: @update_attrs)
  #     assert %{"id" => ^id} = json_response(conn, 200)["data"]

  #     conn = get(conn, Routes.user_path(conn, :show, id))

  #     assert %{
  #              "id" => id,
  #              "icon_path" => "some updated icon_path",
  #              "language" => "some updated language",
  #              "name" => "some updated name",
  #              "notification_number" => 43,
  #              "point" => 43
  #            } = json_response(conn, 200)["data"]
  #   end

  #   test "renders errors when data is invalid", %{conn: conn, user: user} do
  #     conn = put(conn, Routes.user_path(conn, :update, user), user: @invalid_attrs)
  #     assert json_response(conn, 422)["errors"] != %{}
  #   end
  # end

  # describe "delete user" do
  #   setup [:create_user]

  #   test "deletes chosen user", %{conn: conn, user: user} do
  #     conn = delete(conn, Routes.user_path(conn, :delete, user))
  #     assert response(conn, 204)

  #     assert_error_sent 404, fn ->
  #       get(conn, Routes.user_path(conn, :show, user))
  #     end
  #   end
  # end

  defp create_user(_) do
    user = fixture(:user)
    {:ok, user: user}
  end
end

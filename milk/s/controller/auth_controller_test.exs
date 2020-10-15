defmodule MilkWeb.AuthControllerTest do
  use MilkWeb.ConnCase

  alias Milk.Accounts
  alias Milk.Accounts.Auth

  @create_attrs %{
    email: "some email",
    logout_fl: true,
    name: "some name",
    password: "some password"
  }
  @update_attrs %{
    email: "some updated email",
    logout_fl: false,
    name: "some updated name",
    password: "some updated password"
  }
  @invalid_attrs %{email: nil, logout_fl: nil, name: nil, password: nil}

  def fixture(:auth) do
    {:ok, auth} = Accounts.create_auth(@create_attrs)
    auth
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all auth", %{conn: conn} do
      conn = get(conn, Routes.auth_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create auth" do
    test "renders auth when data is valid", %{conn: conn} do
      conn = post(conn, Routes.auth_path(conn, :create), auth: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.auth_path(conn, :show, id))

      assert %{
               "id" => id,
               "email" => "some email",
               "logout_fl" => true,
               "name" => "some name",
               "password" => "some password"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.auth_path(conn, :create), auth: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update auth" do
    setup [:create_auth]

    test "renders auth when data is valid", %{conn: conn, auth: %Auth{id: id} = auth} do
      conn = put(conn, Routes.auth_path(conn, :update, auth), auth: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.auth_path(conn, :show, id))

      assert %{
               "id" => id,
               "email" => "some updated email",
               "logout_fl" => false,
               "name" => "some updated name",
               "password" => "some updated password"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, auth: auth} do
      conn = put(conn, Routes.auth_path(conn, :update, auth), auth: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete auth" do
    setup [:create_auth]

    test "deletes chosen auth", %{conn: conn, auth: auth} do
      conn = delete(conn, Routes.auth_path(conn, :delete, auth))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.auth_path(conn, :show, auth))
      end
    end
  end

  defp create_auth(_) do
    auth = fixture(:auth)
    {:ok, auth: auth}
  end
end

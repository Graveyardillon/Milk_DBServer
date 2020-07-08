defmodule Milk.AccountsTest do
  use Milk.DataCase

  alias Milk.Accounts

  describe "users" do
    alias Milk.Accounts.User

    @valid_attrs %{icon_path: "some icon_path", language: "some language", name: "some name", notification_number: 42, point: 42}
    @update_attrs %{icon_path: "some updated icon_path", language: "some updated language", name: "some updated name", notification_number: 43, point: 43}
    @invalid_attrs %{icon_path: nil, language: nil, name: nil, notification_number: nil, point: nil}

    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_user()

      user
    end

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Accounts.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@valid_attrs)
      assert user.icon_path == "some icon_path"
      assert user.language == "some language"
      assert user.name == "some name"
      assert user.notification_number == 42
      assert user.point == 42
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, %User{} = user} = Accounts.update_user(user, @update_attrs)
      assert user.icon_path == "some updated icon_path"
      assert user.language == "some updated language"
      assert user.name == "some updated name"
      assert user.notification_number == 43
      assert user.point == 43
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user == Accounts.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end
  end

  describe "auth" do
    alias Milk.Accounts.Auth

    @valid_attrs %{email: "some email", logout_fl: true, name: "some name", password: "some password"}
    @update_attrs %{email: "some updated email", logout_fl: false, name: "some updated name", password: "some updated password"}
    @invalid_attrs %{email: nil, logout_fl: nil, name: nil, password: nil}

    def auth_fixture(attrs \\ %{}) do
      {:ok, auth} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_auth()

      auth
    end

    test "list_auth/0 returns all auth" do
      auth = auth_fixture()
      assert Accounts.list_auth() == [auth]
    end

    test "get_auth!/1 returns the auth with given id" do
      auth = auth_fixture()
      assert Accounts.get_auth!(auth.id) == auth
    end

    test "create_auth/1 with valid data creates a auth" do
      assert {:ok, %Auth{} = auth} = Accounts.create_auth(@valid_attrs)
      assert auth.email == "some email"
      assert auth.logout_fl == true
      assert auth.name == "some name"
      assert auth.password == "some password"
    end

    test "create_auth/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_auth(@invalid_attrs)
    end

    test "update_auth/2 with valid data updates the auth" do
      auth = auth_fixture()
      assert {:ok, %Auth{} = auth} = Accounts.update_auth(auth, @update_attrs)
      assert auth.email == "some updated email"
      assert auth.logout_fl == false
      assert auth.name == "some updated name"
      assert auth.password == "some updated password"
    end

    test "update_auth/2 with invalid data returns error changeset" do
      auth = auth_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_auth(auth, @invalid_attrs)
      assert auth == Accounts.get_auth!(auth.id)
    end

    test "delete_auth/1 deletes the auth" do
      auth = auth_fixture()
      assert {:ok, %Auth{}} = Accounts.delete_auth(auth)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_auth!(auth.id) end
    end

    test "change_auth/1 returns a auth changeset" do
      auth = auth_fixture()
      assert %Ecto.Changeset{} = Accounts.change_auth(auth)
    end
  end
end

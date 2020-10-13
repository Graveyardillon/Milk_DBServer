defmodule Milk.AccountsTest do
  use Milk.DataCase

  alias Milk.Accounts

  describe "users" do
    alias Milk.Accounts.User

    @valid_attrs %{icon_path: "some icon_path", language: "some language", name: "some name", notification_number: 42, point: 42,email: "some email", logout_fl: true, password: "some password"}
    @update_attrs %{icon_path: "some updated icon_path", language: "some updated language", name: "some updated name", notification_number: 43, point: 43,  email: "some updated email", logout_fl: false, password: "some updated password"}
    @invalid_attrs %{icon_path: nil, language: nil, name: nil, notification_number: nil, point: nil}


    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_user()

      Accounts.get_user(user.id)
    end

    # test "list_users/0 returns all users" do
    #   user = user_fixture()
    #   assert Accounts.list_users() == [user]
    # end

    # test "get_user!/1 returns the user with given id" do
    #   user = user_fixture()
    #   assert Accounts.get_user(user.id) == user
    # end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@valid_attrs)
      assert user.icon_path == "some icon_path"
      assert user.language == "some language"
      assert user.name == "some name"
      assert user.notification_number == 42
      assert user.point == 42
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, error} = Accounts.create_user(@invalid_attrs)
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

    # test "update_user/2 with invalid data returns error changeset" do
    #   user = user_fixture()
    #   assert {:error, error} = Accounts.update_user(user, @invalid_attrs)
    #   assert user == Accounts.get_user(user.id)
    # end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, _} = Accounts.delete_user(user)
      assert !Accounts.get_user(user.id)
    end

    # test "change_user/1 returns a user changeset" do
    #   user = user_fixture()
    #   assert %Ecto.Changeset{} = Accounts.change_user(user)
    # end
  end

  # describe "profiles" do
  #   alias Milk.Accounts.Profile
  #   alias Milk.Profiles

  #   @valid_attrs %{content_id: 42, content_type: 42, user_id: 42}
  #   @update_attrs %{content_id: 43, content_type: 43, user_id: 43}
  #   @invalid_attrs %{content_id: nil, content_type: nil, user_id: nil}

  #   def profile_fixture(attrs \\ %{}) do
  #     {:ok, profile} =
  #       attrs
  #       |> Enum.into(@valid_attrs)
  #       |> Profiles.add()

  #     profile
  #   end

  #   test "list_profiles/0 returns all profiles" do
  #     profile = profile_fixture()
  #     assert Accounts.list_profiles() == [profile]
  #   end

  #   test "get_profile!/1 returns the profile with given id" do
  #     profile = profile_fixture()
  #     assert Accounts.get_profile!(profile.id) == profile
  #   end

  #   test "create_profile/1 with valid data creates a profile" do
  #     assert {:ok, %Profile{} = profile} = Accounts.create_profile(@valid_attrs)
  #     assert profile.content_id == 42
  #     assert profile.content_type == 42
  #     assert profile.user_id == 42
  #   end

  #   test "create_profile/1 with invalid data returns error changeset" do
  #     assert {:error, %Ecto.Changeset{}} = Accounts.create_profile(@invalid_attrs)
  #   end

  #   test "update_profile/2 with valid data updates the profile" do
  #     profile = profile_fixture()
  #     assert {:ok, %Profile{} = profile} = Accounts.update_profile(profile, @update_attrs)
  #     assert profile.content_id == 43
  #     assert profile.content_type == 43
  #     assert profile.user_id == 43
  #   end

  #   test "update_profile/2 with invalid data returns error changeset" do
  #     profile = profile_fixture()
  #     assert {:error, %Ecto.Changeset{}} = Accounts.update_profile(profile, @invalid_attrs)
  #     assert profile == Accounts.get_profile!(profile.id)
  #   end

  #   test "delete_profile/1 deletes the profile" do
  #     profile = profile_fixture()
  #     assert {:ok, %Profile{}} = Accounts.delete_profile(profile)
  #     assert_raise Ecto.NoResultsError, fn -> Accounts.get_profile!(profile.id) end
  #   end

  #   test "change_profile/1 returns a profile changeset" do
  #     profile = profile_fixture()
  #     assert %Ecto.Changeset{} = Accounts.change_profile(profile)
  #   end
  # end
end

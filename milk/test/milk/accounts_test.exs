defmodule Milk.AccountsTest do
  use Milk.DataCase

  alias Milk.Accounts
  alias Milk.Profiles
  alias Milk.Relations

  describe "users" do
    alias Milk.Accounts.User

    @user_valid_attrs %{"icon_path" => "some icon_path", "language" => "some language", "name" => "some name", "notification_number" => 42, "point" => 42, "email" => "some@email.com", "logout_fl" => true, "password" => "S1ome password"}
    @update_attrs %{icon_path: "some updated icon_path", language: "some updated language", name: "some updated name", notification_number: 43, point: 43,  email: "some updated email", logout_fl: false, password: "S1ome updated password"}
    @invalid_attrs %{"icon_path" => nil, "language" => nil, "name" => nil, "notification_number" => nil, "point" => nil, "email" => nil, "password" => nil}


    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@user_valid_attrs)
        |> Accounts.create_user()

      Accounts.get_user(user.id)
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@user_valid_attrs)
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

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, _} = Accounts.delete_user(user.id, user.auth.password, user.auth.email)
      assert !Accounts.get_user(user.id)
    end
  end

  describe "profiles" do
    alias Milk.Accounts.Profile

    @valid_attrs %{content_id: 42, content_type: "42", user_id: 42}
    @update_attrs %{content_id: 43, content_type: "43", user_id: 42}
    @invalid_attrs %{content_id: nil, content_type: nil, user_id: nil}

    def profile_fixture(attrs \\ %{}) do
      {:ok, profile} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Profiles.create_profile()

      profile
    end
# FIXME:
    # test "list_profiles/0 returns all profiles" do
    #   profile = profile_fixture()
    #   assert Profiles.list_profiles() == [profile]
    # end

    # test "get_profile!/1 returns the profile with given id" do
    #   profile = profile_fixture()
    #   assert Profiles.get_profile!(profile.id) == profile
    # end

    test "create_profile/1 with valid data creates a profile" do
      assert {:ok, %Profile{} = profile} = Profiles.create_profile(@valid_attrs)
      assert profile.content_id == 42
      assert profile.content_type == "42"
      assert profile.user_id == 42
    end

    test "create_profile/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Profiles.create_profile(@invalid_attrs)
    end

    test "update_profile/2 with valid data updates the profile" do
      profile = profile_fixture()
      assert {:ok, %Profile{} = profile} = Profiles.update_profile(profile, @update_attrs)
      assert profile.content_id == 43
      assert profile.content_type == "43"
      assert profile.user_id == 42
    end

    test "update_profile/2 with invalid data returns error changeset" do
      profile = profile_fixture()
      assert {:error, %Ecto.Changeset{}} = Profiles.update_profile(profile, @invalid_attrs)
      # FIXME: 
      # assert profile == Profiles.get_profile!(profile.id)
    end

    test "delete_profile/1 deletes the profile" do
      profile = profile_fixture()
      assert {:ok, %Profile{}} = Profiles.delete_profile(profile)
      assert_raise Ecto.NoResultsError, fn -> Profiles.get_profile!(profile.id) end
    end

    test "change_profile/1 returns a profile changeset" do
      profile = profile_fixture()
      assert %Ecto.Changeset{} = Profiles.change_profile(profile)
    end
  end

  describe "relations" do
    alias Milk.Accounts.Relation

    @valid_attrs %{"id" => 1}
    @update_attrs %{id: 1, followee_id: 1, follower_id: 3}
    @invalid_attrs %{id: nil, followee_id: 0999999999999, follower_id: 999999999}

    def relation_fixture(attrs \\ %{}) do
      {:ok, user1} = Accounts.create_user(%{"name" => "name", "email" => "e@mail.com", "password" => "Password123"})
      {:ok, user2} = Accounts.create_user(%{"name" => "name", "email" => "ew@mail.com", "password" => "Password123"})
      {:ok, relation} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Map.put("followee_id", user1.id)
        |> Map.put("follower_id", user2.id)
        |> Relations.create_relation()

      relation
    end

    # test "list_relations/0 returns all relations" do
    #   relation = relation_fixture()
    #   assert Relations.list_relations() == [relation]
    # end
    # FIXME:
    # test "get_relation!/1 returns the relation with given id" do
    #   relation = relation_fixture()
    #   assert Relations.get_relation!(relation.id) == relation
    # end

    test "create_relation/1 with valid data creates a relation" do
      {:ok, user1} = Accounts.create_user(%{"name" => "name", "email" => "e@mail.com", "password" => "Password123"})
      {:ok, user2} = Accounts.create_user(%{"name" => "name", "email" => "ew@mail.com", "password" => "Password123"})
      assert {:ok, %Relation{} = relation} =
        @valid_attrs
        |> Map.put("followee_id", user1.id)
        |> Map.put("follower_id", user2.id)
        |>Relations.create_relation()
    end

    test "create_relation/1 with invalid data returns error" do
      assert {:error, _} = Relations.create_relation(@invalid_attrs)
    end

    test "update_relation/2 with valid data updates the relation" do
      relation = relation_fixture()
      assert {:ok, %Relation{} = relation} = Relations.update_relation(relation, @update_attrs)
    end

    test "update_relation/2 with invalid data returns unchanged data" do
      relation = relation_fixture()
      assert relation = Relations.update_relation(relation, @invalid_attrs)
      # assert relation == Relations.get_relation!(relation.id)
    end

    test "delete_relation/1 deletes the relation" do
      relation = relation_fixture()
      assert {:ok, %Relation{}} = Relations.delete_relation(relation)
      assert_raise Ecto.NoResultsError, fn -> Relations.get_relation!(relation.id) end
    end

    test "change_relation/1 returns a relation changeset" do
      relation = relation_fixture()
      assert %Ecto.Changeset{} = Relations.change_relation(relation)
    end
  end

  # FIXME: あとでやります
  # describe "chat" do
  #   test "get_users_in_touch/1 returns "
  # end
  describe "auth" do
    alias Milk.Accounts.User

    test "login/1 can login user by email" do
      user = user_fixture()
      login_params = %{
          "password" => @user_valid_attrs["password"],
          "email_or_username" => user.auth.email
        }
      assert %{user: %User{}, token: token} = Accounts.login(login_params)
    end


    test "login/1 can login user by username" do
      user = user_fixture()
      login_params = %{
          "password" => @user_valid_attrs["password"],
          "email_or_username" => user.auth.name
        }
      assert %{user: %User{}, token: token} = Accounts.login(login_params)
    end

    test "login/1 can't login user by invalid username" do
      user_fixture()
      login_params = %{
          "password" => @user_valid_attrs["password"],
          "email_or_username" => "invalid"
        }
      assert is_nil(Accounts.login(login_params))
    end

    test "login/1 can't login user by invalid email" do
      user_fixture()
      login_params = %{
          "password" => @user_valid_attrs["password"],
          "email_or_username" => "invalid@a.com"
        }
      assert is_nil(Accounts.login(login_params))
    end

    test "login/1 can't login user by invalid password" do
      user = user_fixture()
      login_params = %{
          "password" => "@u",
          "email_or_username" => user.auth.email
        }
      assert is_nil(Accounts.login(login_params))
    end
  end
end

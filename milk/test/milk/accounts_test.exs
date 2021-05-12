defmodule Milk.AccountsTest do
  use Milk.DataCase

  alias Milk.{
    Accounts,
    Profiles,
    Relations,
    Chat,
    Repo
  }

  alias Milk.Accounts.{
    User,
    Profile,
    Relation
  }

  alias Milk.Chat.Chats
  alias Milk.UserManager.Guardian

  @user_valid_attrs %{
    "icon_path" => "some icon_path",
    "language" => "some language",
    "name" => "some name",
    "notification_number" => 42,
    "point" => 42,
    "email" => "some@email.com",
    "logout_fl" => true,
    "password" => "S1ome password"
  }
  defp fixture(:user) do
    {:ok, user} =
      %{}
      |> Enum.into(@user_valid_attrs)
      |> Accounts.create_user()

    Accounts.get_user(user.id)
  end

  defp fixture(:chat_member) do
    %{"id" => user_id} = fixture(:user)
    attrs = %{"user_id" => user_id}
    {:ok, chat_member} = Chat.create_chat_member(attrs)
  end

  describe "users get" do
    setup [:create_user]

    @user2_valid_attrs %{
      "icon_path" => "some icon_path",
      "language" => "some language",
      "name" => "some name2",
      "notification_number" => 42,
      "point" => 42,
      "email" => "some2@email.com",
      "logout_fl" => true,
      "password" => "S1ome password"
    }
    @invalid_attrs %{
      "icon_path" => nil,
      "language" => nil,
      "name" => nil,
      "notification_number" => nil,
      "point" => nil,
      "email" => nil,
      "password" => nil
    }

    test "get_user/1 gets a user", %{user: user} do
      assert user.id == Accounts.get_user(user.id).id
    end

    test "check_duplication?/1 checks given name is already taken" do
      assert Accounts.check_duplication?("some name")
      refute Accounts.check_duplication?("not taken name")
    end

    test "get_users_in_touch/1 gets users in touch", %{user: user} do
      {:ok, %User{} = user2} = Accounts.create_user(@user2_valid_attrs)

      {:ok, %Chats{} = _chat} =
        Chat.dialogue(%{"user_id" => user.id, "partner_id" => user2.id, "word" => "Hello"})

      user =
        Accounts.get_users_in_touch(user.id)
        |> hd()

      assert user2.id == user.id
    end

    test "get_user_by_email/1 gets user by given email", %{user: user} do
      u = Accounts.get_user_by_email(user.auth.email)
      assert u.name == user.name
      assert u.auth.email == user.auth.email
    end
  end

  describe "users create" do
    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@user_valid_attrs)
      assert user.icon_path == "some icon_path"
      assert user.language == "some language"
      assert user.name == "some name"
      assert user.notification_number == 42
      assert user.point == 42
    end

    test "create_user/1 with valid data creates a user when id is max" do
      %{@user_valid_attrs | "name" => "same", "email" => "gmreio@kogre.com"}
      |> Map.put("id_for_show", 0)
      |> Accounts.create_user()

      assert {:ok, %User{} = user} =
               Map.put(@user_valid_attrs, "id_for_show", 1_000_000)
               |> Accounts.create_user()

      assert user.id_for_show == 1
      assert user.icon_path == "some icon_path"
      assert user.language == "some language"
      assert user.name == "some name"
      assert user.notification_number == 42
      assert user.point == 42
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, error} = Accounts.create_user(@invalid_attrs)
    end
  end

  defp create_user(_) do
    %{user: fixture(:user)}
  end

  describe "users update" do
    @update_attrs %{
      icon_path: "some updated icon_path",
      language: "some updated language",
      name: "some updated name",
      notification_number: 43,
      point: 43,
      email: "some updated email",
      logout_fl: false,
      password: "S1ome updated password"
    }
    setup [:create_user]

    test "update_user/2 with valid data updates the user", %{user: user} do
      assert {:ok, %User{} = user} = Accounts.update_user(user, @update_attrs)
      assert user.icon_path == "some updated icon_path"
      assert user.language == "some updated language"
      assert user.name == "some updated name"
      assert user.notification_number == 43
      assert user.point == 43
    end

    test "update_user/2 with invalid data returns error", %{user: user} do
      Accounts.create_user(%{@user_valid_attrs | "name" => "same", "email" => "gmreio@kogre.com"})
      # debug = Accounts.update_user(user, Map.put(@update_attrs, :name, "same"))
      # assert Repo.all(User)
      # assert {:error, error} = debug
      assert catch_error(Accounts.update_user(user, Map.put(@update_attrs, :name, "same")))
    end
  end

  describe "change password" do
    setup [:create_user]

    test "change_password_by_email/2 changes password", %{user: user} do
      new_password = "newPassword123"
      assert {:ok, _} = Accounts.change_password_by_email(user.auth.email, new_password)
      user = Accounts.get_user(user.id)
      assert Argon2.verify_pass(new_password, user.auth.password)
    end
  end

  describe "is email exists?" do
    setup [:create_user]

    test "is_email_exists? returns true with created user", %{user: user} do
      assert Accounts.is_email_exists?(user.auth.email)
    end

    test "is_email_exists? returns false", %{user: _} do
      refute Accounts.is_email_exists?("asdf")
    end
  end

  describe "users delete" do
    setup [:create_user]

    @user_valid_attrs %{
      "icon_path" => "some icon_path",
      "language" => "some language",
      "name" => "some name",
      "notification_number" => 42,
      "point" => 42,
      "email" => "some@email.com",
      "logout_fl" => true,
      "password" => "S1ome password"
    }

    test "delete_user/1 deletes the user", %{user: user} do
      login_params = %{
        "password" => @user_valid_attrs["password"],
        "email_or_username" => user.name
      }

      assert {:ok, %User{} = user} = Accounts.login(login_params)
      assert {:ok, token, _} = Guardian.encode_and_sign(user)

      assert {:ok, _} =
               Accounts.delete_user(
                 user.id,
                 @user_valid_attrs["password"],
                 user.auth.email,
                 token
               )

      assert !Accounts.get_user(user.id)
    end

    test "delete_user/1 with invalid token returns errors", %{user: user} do
      login_params = %{
        "password" => @user_valid_attrs["password"],
        "email_or_username" => user.name
      }

      assert {:ok, %User{}} = Accounts.login(login_params)

      assert {:error, "That token does not exist"} =
               Accounts.delete_user(user.id, @user_valid_attrs["password"], user.auth.email, "a")

      assert Accounts.get_user(user.id)
    end
  end

  describe "login" do
    setup [:create_user]

    @user_valid_attrs %{
      "icon_path" => "some icon_path",
      "language" => "some language",
      "name" => "some name",
      "notification_number" => 42,
      "point" => 42,
      "email" => "some@email.com",
      "logout_fl" => true,
      "password" => "S1ome password"
    }

    test "login/1 can login user by email", %{user: user} do
      login_params = %{
        "password" => @user_valid_attrs["password"],
        "email_or_username" => user.auth.email
      }

      assert {:ok, %User{}} = Accounts.login(login_params)
    end

    test "login/1 can login user by username", %{user: user} do
      login_params = %{
        "password" => @user_valid_attrs["password"],
        "email_or_username" => user.name
      }

      assert {:ok, %User{}} = Accounts.login(login_params)
    end

    test "login/1 can't login user by invalid username", %{user: user} do
      login_params = %{
        "password" => @user_valid_attrs["password"],
        "email_or_username" => "invalid"
      }

      assert {:error, nil} == Accounts.login(login_params)
    end

    test "login/1 can't login user by invalid email", %{user: user} do
      login_params = %{
        "password" => @user_valid_attrs["password"],
        "email_or_username" => "invalid@a.com"
      }

      assert {:error, nil} == Accounts.login(login_params)
    end

    test "login/1 can't login user by invalid password", %{user: user} do
      login_params = %{
        "password" => "powd",
        "email_or_username" => user.auth.email
      }

      assert {:error, nil} == Accounts.login(login_params)
    end

    test "login_forced/1 logins user", %{user: user} do
      assert user ==
               %{
                 "email" => @user_valid_attrs["email"],
                 "password" => @user_valid_attrs["password"]
               }
               |> Accounts.login_forced()
    end
  end

  describe "logout" do
    setup [:create_user]

    @user_valid_attrs %{
      "icon_path" => "some icon_path",
      "language" => "some language",
      "name" => "some name",
      "notification_number" => 42,
      "point" => 42,
      "email" => "some@email.com",
      "logout_fl" => true,
      "password" => "S1ome password"
    }

    test "logout/1 can logout user by id", %{user: user} do
      login_params = %{
        "password" => @user_valid_attrs["password"],
        "email_or_username" => user.auth.email
      }

      {:ok, %User{}} = Accounts.login(login_params)
      assert Accounts.logout(user.id)
    end
  end

  defp profile_fixture(attrs \\ %{}) do
    valid_attrs = %{content_id: 42, content_type: "42", user_id: 42}

    {:ok, profile} =
      attrs
      |> Enum.into(valid_attrs)
      |> Profiles.create_profile()

    profile
  end

  describe "get profiles" do
  end

  describe "create profiles" do
    @valid_attrs %{content_id: 42, content_type: "42", user_id: 42}
    @update_attrs %{content_id: 43, content_type: "43", user_id: 42}
    @invalid_attrs %{content_id: nil, content_type: nil, user_id: nil}

    test "create_profile/1 with valid data creates a profile" do
      assert {:ok, %Profile{} = profile} = Profiles.create_profile(@valid_attrs)
      assert profile.content_id == 42
      assert profile.content_type == "42"
      assert profile.user_id == 42
    end

    test "create_profile/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Profiles.create_profile(@invalid_attrs)
    end
  end

  describe "update profiles" do
    @update_attrs %{content_id: 43, content_type: "43", user_id: 42}
    @invalid_attrs %{content_id: nil, content_type: nil, user_id: nil}

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
    end
  end

  describe "delete profiles" do
    test "delete_profile/1 deletes the profile" do
      profile = profile_fixture()
      assert {:ok, %Profile{}} = Profiles.delete_profile(profile)
      assert_raise Ecto.NoResultsError, fn -> Profiles.get_profile!(profile.id) end
    end
  end

  defp relation_fixture(_attrs \\ %{}) do
    valid_attrs = %{"id" => 1}

    {:ok, user1} =
      Accounts.create_user(%{
        "name" => "name",
        "email" => "e@mail.com",
        "password" => "Password123"
      })

    {:ok, user2} =
      Accounts.create_user(%{
        "name" => "name2",
        "email" => "ew@mail.com",
        "password" => "Password123"
      })

    {:ok, relation} =
      valid_attrs
      |> Map.put("followee_id", user1.id)
      |> Map.put("follower_id", user2.id)
      |> Relations.create_relation()

    relation
  end

  describe "get relations" do
  end

  describe "create relations" do
    @valid_attrs %{"id" => 1}
    @update_attrs %{id: 1, followee_id: 1, follower_id: 3}
    @invalid_attrs %{id: nil, followee_id: 0_999_999_999_999, follower_id: 999_999_999}

    test "create_relation/1 with valid data creates a relation" do
      {:ok, user1} =
        Accounts.create_user(%{
          "name" => "name",
          "email" => "e@mail.com",
          "password" => "Password123"
        })

      {:ok, user2} =
        Accounts.create_user(%{
          "name" => "name2",
          "email" => "ew@mail.com",
          "password" => "Password123"
        })

      assert {:ok, %Relation{} = relation} =
               @valid_attrs
               |> Map.put("followee_id", user1.id)
               |> Map.put("follower_id", user2.id)
               |> Relations.create_relation()
    end

    test "create_relation/1 with invalid data returns error" do
      assert {:error, _} = Relations.create_relation(@invalid_attrs)
    end
  end

  describe "update relations" do
    @update_attrs %{id: 1, followee_id: 1, follower_id: 3}
    @invalid_attrs %{id: nil, followee_id: 0_999_999_999_999, follower_id: 999_999_999}

    test "update_relation/2 with valid data updates the relation" do
      relation = relation_fixture()
      assert {:ok, %Relation{} = relation} = Relations.update_relation(relation, @update_attrs)
    end

    test "update_relation/2 with invalid data returns unchanged data" do
      relation = relation_fixture()
      assert relation = Relations.update_relation(relation, @invalid_attrs)
      # assert relation == Relations.get_relation!(relation.id)
    end
  end

  describe "delete relations" do
    test "delete_relation/1 deletes the relation" do
      relation = relation_fixture()
      assert {:ok, %Relation{}} = Relations.delete_relation(relation)
      assert_raise Ecto.NoResultsError, fn -> Relations.get_relation!(relation.id) end
    end
  end

  # describe "private_rooms" do
  #   setup [:create_chat_member]
  #   test "get_private_rooms/1 returns　user's private chat rooms" do
  #   end
  # end

  describe "icon_path" do
    setup [:create_user]

    test "update_icon_path/2 updates icon path", %{user: user} do
      assert Accounts.update_icon_path(user, "icon_path")
    end
  end

  defp create_chat_member(_) do
    %{chat_member: fixture(:chat_member)}
  end
end

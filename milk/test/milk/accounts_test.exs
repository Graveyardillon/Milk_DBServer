defmodule Milk.AccountsTest do
  use Milk.DataCase

  import Common.Sperm

  alias Milk.{
    Accounts,
    Relations,
    Chat
  }

  alias Milk.Accounts.{
    User,
    Relation
  }

  alias Milk.Chat.Chats
  alias Milk.UserManager.Guardian

  defp fixture_user(n \\ 0) do
    attrs = %{
      "icon_path" => "some icon_path",
      "language" => "some language",
      "name" => to_string(n) <> "some name",
      "notification_number" => 42,
      "point" => 42,
      "email" => to_string(n) <> "some@email.com",
      "logout_fl" => true,
      "password" => "S1ome password"
    }

    {:ok, user} = Accounts.create_user(attrs)
    Accounts.get_user(user.id)
  end

  defp create_user(_) do
    %{user: fixture_user()}
  end

  # defp fixture(:chat_member) do
  #   %{"id" => user_id} = fixture_user()
  #   attrs = %{"user_id" => user_id}
  #   {:ok, _chat_member} = Chat.create_chat_member(attrs)
  # end

  describe "users get" do
    setup [:create_user]

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

    test "check_duplication?/1 checks given name is already taken", %{user: user} do
      assert Accounts.check_duplication?(user.name)
      refute Accounts.check_duplication?("not taken name")
    end

    test "get_users_in_touch/1 gets users in touch", %{user: user} do
      %User{} = user2 = fixture_user(2)

      {:ok, %Chats{} = _chat} = Chat.dialogue(%{"user_id" => user.id, "partner_id" => user2.id, "word" => "Hello"})

      user =
        Accounts.get_users_in_touch(user.id)
        |> hd()

      assert user2.id == user.id
    end

    test "get_user_by_email/1 gets user by given email", %{user: user} do
      user = Accounts.load_user(user.id)
      u = Accounts.get_user_by_email(user.auth.email)
      assert u.name == user.name
      assert u.auth.email == user.auth.email
    end

    test "search", %{user: user} do
      "some"
      |> Accounts.search()
      |> Enum.map(fn u ->
        assert u.id == user.id
      end)
      |> length()
      |> Kernel.==(1)
      |> assert()

      "dddd"
      |> Accounts.search()
      |> length()
      |> Kernel.==(0)
      |> assert()
    end
  end

  describe "count users" do
    test "count user number" do
      assert Accounts.get_user_number() == 0
      x = 20

      1..x
      |> Enum.to_list()
      |> Enum.each(fn n ->
        fixture_user(n)
        assert Accounts.get_user_number() == n
      end)

      assert Accounts.get_user_number() == x
    end
  end

  describe "users create" do
    test "create_user/1 with valid data creates a user" do
      assert %User{} = user = fixture_user()
      assert user.icon_path == "some icon_path"
      assert user.language == "some language"
      assert user.name == "0some name"
      assert user.notification_number == 42
      assert user.point == 42
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, _} = Accounts.create_user(@invalid_attrs)
    end
  end

  describe "create oauth user" do
    test "create" do
    end
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
      user = Accounts.load_user(user.id)
      assert {:ok, %User{} = user} = Accounts.update_user(user, @update_attrs)
      assert user.icon_path == "some updated icon_path"
      assert user.language == "some updated language"
      assert user.name == "some updated name"
      assert user.notification_number == 43
      assert user.point == 43
    end

    # test "update_user/2 with invalid data returns error", %{user: user} do
    #   # debug = Accounts.update_user(user, Map.put(@update_attrs, :name, "same"))
    #   # assert Repo.all(User)
    #   # assert {:error, error} = debug
    #   assert catch_error(Accounts.update_user(user, Map.put(@update_attrs, :name, user.name)))
    # end
  end

  describe "change password" do
    setup [:create_user]

    test "change_password_by_email/2 changes password", %{user: user} do
      new_password = "newPassword123"
      user = Accounts.load_user(user.id)
      assert {:ok, _} = Accounts.change_password_by_email(user.auth.email, new_password)
      user = Accounts.load_user(user.id)
      assert Argon2.verify_pass(new_password, user.auth.password)
    end
  end

  describe "is email exists?" do
    setup [:create_user]

    test "email_exists? returns true with created user", %{user: user} do
      user = Accounts.load_user(user.id)
      assert Accounts.email_exists?(user.auth.email)
    end

    test "email_exists? returns false", %{user: _} do
      refute Accounts.email_exists?("asdf")
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

      user = Accounts.load_user(user.id)

      assert {:ok, _} =
               Accounts.delete_user(
                 user.id,
                 @user_valid_attrs["password"],
                 user.auth.email,
                 token
               )

      user.id
      |> Accounts.get_user()
      |> is_nil()
      |> assert()
    end

    test "delete_user/1 with invalid token returns errors", %{user: user} do
      login_params = %{
        "password" => @user_valid_attrs["password"],
        "email_or_username" => user.name
      }

      assert {:ok, %User{}} = Accounts.login(login_params)
      user = Accounts.load_user(user.id)

      assert {:error, "That token does not exist"} = Accounts.delete_user(user.id, @user_valid_attrs["password"], user.auth.email, "a")

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
      user = Accounts.load_user(user.id)
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

    test "login/1 can't login user by invalid username" do
      login_params = %{
        "password" => @user_valid_attrs["password"],
        "email_or_username" => "invalid"
      }

      assert {:error, nil} == Accounts.login(login_params)
    end

    test "login/1 can't login user by invalid email" do
      login_params = %{
        "password" => @user_valid_attrs["password"],
        "email_or_username" => "invalid@a.com"
      }

      assert {:error, nil} == Accounts.login(login_params)
    end

    test "login/1 can't login user by invalid password", %{user: user} do
      user = Accounts.load_user(user.id)
      login_params = %{
        "password" => "powd",
        "email_or_username" => user.auth.email
      }

      assert {:error, nil} == Accounts.login(login_params)
    end

    test "login_forced/1 logins user", %{user: user} do
      user = Accounts.load_user(user.id)

      %{"email" => user.auth.email, "password" => "S1ome password"}
      |> Accounts.login_forced()
      |> then(fn login_user ->
        assert login_user.id == user.id
      end)
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
      user = Accounts.load_user(user.id)
      login_params = %{
        "password" => @user_valid_attrs["password"],
        "email_or_username" => user.auth.email
      }

      {:ok, %User{}} = Accounts.login(login_params)
      assert {:ok, _} = Accounts.logout(user.id)
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

      assert {:ok, %Relation{}} =
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
      assert {:ok, %Relation{}} = Relations.update_relation(relation, @update_attrs)
    end

    test "update_relation/2 with invalid data returns unchanged data" do
      relation = relation_fixture()
      assert _ = Relations.update_relation(relation, @invalid_attrs)
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
      assert Accounts.update_icon_path(user.id, "icon_path")
    end
  end

  # defp create_chat_member(_) do
  #   %{chat_member: fixture(:chat_member)}
  # end

  describe "get devices by user id" do
    test "works" do
      token = "tesToken0101"
      user = fixture_user()

      Accounts.register_device(user.id, token)
      |> elem(1)
      |> (fn device ->
            assert device.token == token
            assert device.user_id == user.id
          end).()

      user.id
      |> Accounts.get_devices_by_user_id()
      |> Enum.map(fn device ->
        assert device.user_id == user.id
        assert device.token == token
      end)
      |> length()
      |> (fn len ->
            assert len == 1
          end).()
    end
  end

  describe "register device" do
    test "works" do
      token = "tesToken0101"
      user = fixture_user()

      Accounts.register_device(user.id, token)
      |> elem(1)
      |> (fn device ->
            assert device.token == token
            assert device.user_id == user.id
          end).()

      token
      |> Accounts.get_device()
      |> (fn device ->
            assert device.token == token
            assert device.user_id == user.id
          end).()
    end
  end

  describe "unregister device" do
    test "works" do
      token = "tesToken0101"
      user = fixture_user()

      {:ok, device} = Accounts.register_device(user.id, token)

      assert {:ok, _} = Accounts.unregister_device(device)
    end
  end

  describe "create and get and update external service" do
    test "works" do
      user = fixture_user()

      content = "@papillon6814"
      name = "Twitter"

      Map.new()
      |> Map.put(:user_id, user.id)
      |> Map.put(:content, content)
      |> Map.put(:name, name)
      |> Accounts.create_external_service()
      |> elem(1)
      ~> external_service

      assert external_service.user_id == user.id
      assert external_service.content == content
      assert external_service.name == name

      user
      |> Map.get(:id)
      |> Accounts.get_external_services()
      ~> external_services
      |> Enum.map(fn external_service ->
        refute is_nil(external_service.id)
        assert external_service.user_id == user.id
        assert external_service.content == content
        assert external_service.name == name
      end)
      |> length()
      |> Kernel.==(1)
      |> assert()

      ucontent = "@papilo123"
      uname = "twotter"

      external_services
      |> Enum.map(fn external_service ->
        external_service
        |> Accounts.update_external_service(%{content: ucontent, name: uname})
        |> elem(1)
        ~> external_service

        assert external_service.name == uname
        assert external_service.content == ucontent
      end)
    end
  end

  describe "user data statistics" do
    test "collect user/0" do
      fixture_user()
      {:ok, _user1} =
        Accounts.create_user(%{
          "name" => "name",
          "email" => "e@mail.com",
          "password" => "Password123"
        })

      {:ok, _user2} =
        Accounts.create_user(%{
          "name" => "name2",
          "email" => "ew@mail.com",
          "password" => "Password123"
        })
      today = Timex.now()
      assert Accounts.collect_user == %{today.year * 10000 + today.month * 100 + today.day => 3}
    end

    test "collect user/0 divides date" do
      fixture_user()
      {:ok, _user1} =
        Accounts.create_user(%{
          "name" => "name",
          "email" => "e@mail.com",
          "password" => "Password123"
        })

      {:ok, _user2} =
        Accounts.create_user(%{
          "name" => "name2",
          "email" => "ew@mail.com",
          "password" => "Password123",
          "create_time" => Timex.now() |> Timex.add(Timex.Duration.from_days(-7))
        })
      today = Timex.now()
      assert Accounts.collect_user == %{today.year * 10000 + today.month * 100 + today.day => 3}
    end
  end
end

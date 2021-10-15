defmodule MilkWeb.UserControllerTest do
  use MilkWeb.ConnCase
  use Common.Fixtures

  alias Milk.Accounts

  @create_attrs %{
    "icon_path" => "some icon_path",
    "language" => "some language",
    "name" => "some name",
    "notification_number" => 42,
    "point" => 42,
    "password" => "Password123",
    "email" => "e@mail.com"
  }
  @invalid_attrs %{icon_path: nil, language: nil, name: nil, notification_number: nil, point: nil}

  def fixture(:user) do
    {:ok, user} = Accounts.create_user(@create_attrs)
    user
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "get user number" do
    test "works", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :number))
      assert json_response(conn, 200)["result"]
      assert json_response(conn, 200)["num"] == 0

      x = 20

      1..x
      |> Enum.to_list()
      |> Enum.each(fn n ->
        fixture_user(num: n)
        conn = get(conn, Routes.user_path(conn, :number))
        assert json_response(conn, 200)["result"]
        assert json_response(conn, 200)["num"] == n
      end)
    end
  end

  describe "check username duplication" do
    test "works", %{conn: conn} do
      _user = fixture(:user)

      conn = get(conn, Routes.user_path(conn, :check_username_duplication), name: "some name")
      refute json_response(conn, 200)["is_unique"]

      conn =
        get(conn, Routes.user_path(conn, :check_username_duplication), name: "WHATaUNIQUEname")

      assert json_response(conn, 200)["is_unique"]
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
      {:ok, user} =
        Accounts.create_user(%{
          "name" => "name",
          "email" => "e@mail.com",
          "password" => "Password123"
        })

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

    # FIXME: スペースのやつはうまく動いていないらしい
    # test "renders errors when password includes space", %{conn: conn} do
    #   attrs = %{@create_attrs | "password" => "Password 123", "name" => "invalid"}
    #   conn = post(conn, Routes.user_path(conn, :create), user: attrs)
    #   assert json_response(conn, 200) == 103
    # end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @invalid_attrs)
      assert json_response(conn, 200)["errors"] != %{}
    end
  end

  describe "sign in with discord" do
    test "works", %{conn: conn} do
      email = "discord@mail.com"
      username = "discordkun"
      discriminator = "#1234"
      discord_id = "1234321"

      conn =
        post(conn, Routes.user_path(conn, :signin_with_discord), %{
          discord_id: discord_id,
          email: email,
          username: username,
          discriminator: discriminator
        })

      response = json_response(conn, 200)

      assert response["result"]
      assert is_binary(response["token"])

      data = response["data"]

      assert data["email"] == email
      assert data["language"] == "japan"
      assert data["name"] == username
      refute is_nil(data["id"])
    end
  end

  describe "sign in with apple" do
    test "works", %{conn: conn} do
      email = "apple@icloud.com"
      username = "applechan"
      apple_id = email

      conn = post(conn, Routes.user_path(conn, :signin_with_apple), %{
        email: email,
        username: username,
        apple_id: apple_id
      })

      response = json_response(conn, 200)

      assert response["result"]
      assert is_binary(response["token"])

      data = response["data"]

      assert data["email"] == email
      assert data["language"] == "japan"
      assert data["name"] == username
      refute is_nil(data["id"])

      conn = post(conn, Routes.user_path(conn, :signin_with_apple), %{
        apple_id: apple_id
      })

      response = json_response(conn, 200)

      assert response["result"]
      assert is_binary(response["token"])

      data = response["data"]

      assert data["email"] == email
      assert data["language"] == "japan"
      assert data["name"] == username
      refute is_nil(data["id"])
    end

    test "does not work", %{conn: conn} do
      apple_id = "apple2@icloud.com"

      conn = post(conn, Routes.user_path(conn, :signin_with_apple), %{
        apple_id: apple_id
      })

      refute json_response(conn, 200)["result"]
    end
  end

  describe "users in touch" do
    test "works", %{conn: conn} do
      {:ok, user1} =
        Accounts.create_user(%{
          "name" => "name1",
          "email" => "e1@mail.com",
          "password" => "Password123",
          "logout_fl" => true
        })

      {:ok, user2} =
        Accounts.create_user(%{
          "name" => "name2",
          "email" => "e2@mail.com",
          "password" => "Password123",
          "logout_fl" => true
        })

      conn =
        post(conn, Routes.chats_path(conn, :create_dialogue),
          chat: %{user_id: user1.id, partner_id: user2.id, word: "Hello"}
        )

      conn = get(conn, Routes.user_path(conn, :users_in_touch), user_id: user1.id)

      assert json_response(conn, 200)["result"]

      json_response(conn, 200)
      |> Map.get("data")
      |> Enum.map(fn user ->
        assert user["id"] == user2.id
      end)
      |> length()
      |> (fn len ->
            assert len == 1
          end).()
    end
  end

  describe "login user" do
    test "works", %{conn: conn} do
      {:ok, user} =
        Accounts.create_user(%{
          "name" => "name",
          "email" => "e@mail.com",
          "password" => "Password123",
          "logout_fl" => true
        })

      conn =
        post(conn, Routes.user_path(conn, :login),
          user: %{"email_or_username" => "e@mail.com", "password" => "Password123"}
        )

      response = json_response(conn, 200)

      assert response["result"]

      response
      |> Map.get("token")
      |> is_binary()
      |> (fn bool ->
            assert bool
          end).()

      response
      |> Map.get("data")
      |> (fn u ->
            assert u["email"] == user.auth.email
          end).()
    end

    test "renders error when invalid email", %{conn: conn} do
      {:ok, _user} =
        Accounts.create_user(%{
          "name" => "name",
          "email" => "e@mail.com",
          "password" => "Password123",
          "logout_fl" => true
        })

      conn =
        post(conn, Routes.user_path(conn, :login),
          user: %{"email_or_username" => "ew@mail.com", "password" => "Password123"}
        )

      assert json_response(conn, 200)["error_code"] == 104
    end

    test "renders error when invalid password", %{conn: conn} do
      {:ok, _user} =
        Accounts.create_user(%{
          "name" => "name",
          "email" => "e@mail.com",
          "password" => "Password123",
          "logout_fl" => true
        })

      conn =
        post(conn, Routes.user_path(conn, :login),
          user: %{"email_or_username" => "e@mail.com", "password" => "Password1234z"}
        )

      assert json_response(conn, 200)["error_code"] == 104
    end
  end

  describe "search" do
    test "works", %{conn: conn} do
      {:ok, user1} =
        Accounts.create_user(%{
          "name" => "name1",
          "email" => "e1@mail.com",
          "password" => "Password123",
          "logout_fl" => true
        })

      ok_text = "ame"
      conn = get(conn, Routes.user_path(conn, :search), text: ok_text)

      json_response(conn, 200)
      |> Map.get("data")
      |> Enum.map(fn user ->
        assert user["id"] == user1.id
      end)
      |> length()
      |> Kernel.==(1)
      |> assert()

      ng_text = "royalty"
      conn = get(conn, Routes.user_path(conn, :search), text: ng_text)

      json_response(conn, 200)
      |> Map.get("result")
      |> refute()
    end

    test "team filter", %{conn: conn} do
      tournament = fixture_tournament(is_team: true, type: 2, capacity: 3)
      fill_with_team(tournament.id)

      user = fixture_user(num: 12345)

      ok_text = "name"

      conn =
        get(conn, Routes.user_path(conn, :search),
          text: ok_text,
          team_filter: true,
          tournament_id: tournament.id
        )

      assert json_response(conn, 200)["result"]

      conn
      |> json_response(200)
      |> Map.get("data")
      |> Enum.each(fn searched_user ->
        assert searched_user["id"] == tournament.master_id || searched_user["id"] == user.id
      end)
    end
  end

  describe "logout" do
    test "works", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @create_attrs)
      response = json_response(conn, 200)
      token = response["token"]
      user = response["data"]

      conn = post(conn, Routes.user_path(conn, :logout), id: user["id"], token: token)
      assert json_response(conn, 200)["result"]
    end
  end

  describe "update" do
    test "update", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @create_attrs)
      response = json_response(conn, 200)
      token = response["token"]
      user = response["data"]

      attrs = %{"name" => "updated name"}

      conn =
        post(conn, Routes.user_path(conn, :update), %{id: user["id"], user: attrs, token: token})

      json_response(conn, 200)
      |> Map.get("data")
      |> (fn updated_user ->
            assert updated_user["name"] == attrs["name"]
          end).()

      attrs = %{"name" => "shold not work"}
      conn = post(conn, Routes.user_path(conn, :update), %{id: user["id"], user: attrs})
      assert json_response(conn, 200)["message"] == "Missing token"
    end
  end

  describe "delete user" do
    test "works", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @create_attrs)
      response = json_response(conn, 200)
      token = response["token"]
      user = response["data"]

      conn =
        delete(conn, Routes.user_path(conn, :delete), %{
          id: user["id"],
          password: @create_attrs["password"],
          email: user["email"],
          token: token
        })

      assert json_response(conn, 200)["result"]
    end

    test "does not work (invalid password)", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @create_attrs)
      response = json_response(conn, 200)
      token = response["token"]
      user = response["data"]

      conn =
        delete(conn, Routes.user_path(conn, :delete), %{
          id: user["id"],
          password: "wrong_passw0rD",
          email: user["email"],
          token: token
        })

      refute json_response(conn, 200)["result"]
    end

    test "does not work (invalid token)", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @create_attrs)
      response = json_response(conn, 200)
      user = response["data"]

      conn =
        delete(conn, Routes.user_path(conn, :delete), %{
          id: user["id"],
          password: @create_attrs["password"],
          email: user["email"],
          token: "toooken"
        })

      refute json_response(conn, 200)["result"]
    end

    test "does not work (invalid email)", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @create_attrs)
      response = json_response(conn, 200)
      token = response["token"]
      user = response["data"]

      conn =
        delete(conn, Routes.user_path(conn, :delete), %{
          id: user["id"],
          password: @create_attrs["password"],
          email: "wrong_email@wrong.wng",
          token: token
        })

      refute json_response(conn, 200)["result"]
    end
  end

  describe "change password" do
    test "changes password with valid request", %{conn: conn} do
      email = "e@mail.com"
      password = "Password123"
      new_password = "321passworD"

      {:ok, user} =
        Accounts.create_user(%{
          "name" => "name",
          "email" => email,
          "password" => password,
          "logout_fl" => true
        })

      # トークンを取得するためにconf_num_controllerの中の処理を直接行う
      token =
        :crypto.strong_rand_bytes(10)
        |> Base.encode32()
        |> binary_part(0, 10)

      Milk.Email.Auth.set_token(%{email => token})

      conn =
        post(conn, Routes.user_path(conn, :change_password), %{
          "email" => email,
          "token" => token,
          "new_password" => new_password
        })

      assert json_response(conn, 200)["result"]
      user = Accounts.get_user(user.id)
      assert Argon2.verify_pass(new_password, user.auth.password)
    end

    test "cannot change password with invalid request", %{conn: conn} do
      email = "e@mail.com"
      password = "Password123"
      new_password = "321passworD"

      {:ok, _user} =
        Accounts.create_user(%{
          "name" => "name",
          "email" => email,
          "password" => password,
          "logout_fl" => true
        })

      # トークンを取得するためにconf_num_controllerの中の処理を直接行う
      token =
        :crypto.strong_rand_bytes(10)
        |> Base.encode32()
        |> binary_part(0, 10)

      Milk.Email.Auth.set_token(%{email => token})

      wrong_token = "invalid"

      conn =
        post(conn, Routes.user_path(conn, :change_password), %{
          "email" => email,
          "token" => wrong_token,
          "new_password" => new_password
        })

      refute json_response(conn, 200)["result"]
    end
  end

  # defp create_user(_) do
  #   user = fixture(:user)
  #   {:ok, user: user}
  # end
end

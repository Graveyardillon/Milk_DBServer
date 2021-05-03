defmodule MilkWeb.RelationControllerTest do
  use MilkWeb.ConnCase

  alias Milk.{
    Accounts,
    Relations
  }

  defp fixture_user(num \\ 0) do
    {:ok, user} =
      Map.new()
      |> Map.put("icon_path", "my_icon_path")
      |> Map.put("language", "my_language")
      |> Map.put("name", to_string(num) <> "my_name")
      |> Map.put("notification_number", 0)
      |> Map.put("point", 0)
      |> Map.put("password", "Password123")
      |> Map.put("email", to_string(num) <> "a@mail.com")
      |> Accounts.create_user()
    user
  end

  defp create_users(_) do
    user1 = fixture_user(1)
    user2 = fixture_user(2)
    %{user1: user1, user2: user2}
  end

  defp create_relation(_) do
    %{user1: user1, user2: user2} = create_users(nil)
    Relations.create_relation(%{"follower_id" => user1.id, "followee_id" => user2.id})
    %{user1: user1, user2: user2}
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create" do
    setup [:create_users]

    test "works", %{conn: conn, user1: user1, user2: user2} do
      conn = post(conn, Routes.relation_path(conn, :create), relation: %{follower_id: user2.id, followee_id: user1.id})
      assert json_response(conn, 200)["result"]
    end
  end

  describe "delete" do
    setup [:create_relation]

    test "works", %{conn: conn, user1: user1, user2: user2} do
      conn = post(conn, Routes.relation_path(conn, :delete), relation: %{follower_id: user1.id, followee_id: user2.id})
      assert json_response(conn, 200)["result"]
    end
  end

  describe "following list" do
    setup [:create_relation]

    test "works", %{conn: conn, user1: user1, user2: user2} do
      conn = get(conn, Routes.relation_path(conn, :following_list), user_id: user1.id)
      json_response(conn, 200)
      |> Map.get("data")
      |> Enum.map(fn user ->
        assert user["bio"] == user2.bio
        assert user["email"] == user2.auth.email
        assert user["id"] == user2.id
        assert user["id_for_show"] == user2.id_for_show
        assert user["language"] == user2.language
        assert user["name"] == user2.name
      end)
      |> length()
      |> (fn len ->
        assert len == 1
      end).()
    end
  end

  describe "following id list" do
    setup [:create_relation]

    test "works", %{conn: conn, user1: user1, user2: user2} do
      conn = get(conn, Routes.relation_path(conn, :following_id_list), user_id: user1.id)
      json_response(conn, 200)
      |> (fn response ->
        assert response["result"]
        response
      end).()
      |> Map.get("following")
      |> Enum.map(fn id ->
        assert id == user2.id
      end)
      |> length()
      |> (fn len ->
        assert len == 1
      end).()
    end
  end

  describe "followers list" do
    setup [:create_relation]

    test "works", %{conn: conn, user1: user1, user2: user2} do
      conn = get(conn, Routes.relation_path(conn, :followers_list), user_id: user2.id)
      json_response(conn, 200)
      |> Map.get("data")
      |> Enum.map(fn user ->
        assert user["bio"] == user1.bio
        assert user["email"] == user1.auth.email
        assert user["id"] == user1.id
        assert user["id_for_show"] == user1.id_for_show
        assert user["language"] == user1.language
        assert user["name"] == user1.name
      end)
      |> length()
      |> (fn len ->
        assert len == 1
      end).()
    end
  end

  describe "followers id list" do
    setup [:create_relation]

    test "works", %{conn: conn, user1: user1, user2: user2} do
      conn = get(conn, Routes.relation_path(conn, :followers_id_list), user_id: user2.id)
      json_response(conn, 200)
      |> (fn response ->
        assert response["result"]
        response
      end).()
      |> Map.get("following")
      |> Enum.map(fn id ->
        assert id == user1.id
      end)
      |> length()
      |> (fn len ->
        assert len == 1
      end).()
    end
  end

  describe "block user and get blocked users" do
    test "both works", %{conn: conn} do
      user1 = fixture_user(1)
      user2 = fixture_user(2)

      conn = post(conn, Routes.relation_path(conn, :block_user), user_id: user1.id, blocked_user_id: user2.id)
      assert json_response(conn, 200)["result"]

      conn = get(conn, Routes.relation_path(conn, :blocked_users), user_id: user1.id)
      assert json_response(conn, 200)["result"]
      json_response(conn, 200)
      |> Map.get("data")
      |> Enum.map(fn user ->
        assert user["id"] == user2.id
        assert user["email"] == user2.auth.email
        assert user["icon_path"] == user2.icon_path
        assert user["bio"] == user2.bio
        assert user["name"] == user2.name
        assert user["id_for_show"] == user2.id_for_show
        assert user["language"] == user2.language
      end)
      |> length()
      |> (fn len ->
        assert len == 1
      end).()
    end
  end

  describe "unblock user" do
    test "works", %{conn: conn} do
      user1 = fixture_user(1)
      user2 = fixture_user(2)

      conn = post(conn, Routes.relation_path(conn, :block_user), user_id: user1.id, blocked_user_id: user2.id)
      conn = get(conn, Routes.relation_path(conn, :blocked_users), user_id: user1.id)
      json_response(conn, 200)
      |> Map.get("data")
      |> length()
      |> (fn len ->
        assert  len == 1
      end).()

      conn = post(conn, Routes.relation_path(conn, :unblock_user), user_id: user1.id, blocked_user_id: user2.id)
      assert json_response(conn, 200)["result"]
      conn = get(conn, Routes.relation_path(conn, :blocked_users), user_id: user1.id)
      json_response(conn, 200)
      |> Map.get("data")
      |> length()
      |> (fn len ->
        assert len == 0
      end).()
    end
  end
end

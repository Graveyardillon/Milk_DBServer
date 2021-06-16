defmodule MilkWeb.NotifControllerTest do
  use MilkWeb.ConnCase

  alias Milk.{
    Accounts,
    Notif
  }

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
    user
  end

  defp set_notifications(user_id, n) do
    1..n
    |> Enum.to_list()
    |> Enum.map(fn n ->
      %{
        "content" => "chore: #{n}",
        "process_code" => 0,
        "data" => nil,
        "user_id" => user_id
      }
      |> Notif.create_notification()
      |> elem(1)
    end)
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "get list" do
    test "works", %{conn: conn} do
      user = fixture_user()

      Enum.each(1..4, fn _n ->
        %{
          "content" => "chore",
          "process_code" => 0,
          "data" => nil,
          "user_id" => user.id
        }
        |> Notif.create_notification()
      end)

      conn = get(conn, Routes.notif_path(conn, :get_list), user_id: user.id)
      response = json_response(conn, 200)

      assert response["result"]

      response
      |> Map.get("data")
      |> Enum.map(fn notification ->
        assert notification["content"] == "chore"
        assert notification["process_code"] == 0
        assert is_nil(notification["data"])
        assert notification["user_id"] == user.id
      end)
      |> length()
      |> (fn len ->
            assert len == 4
          end).()
    end
  end

  describe "create" do
    test "works", %{conn: conn} do
      user = fixture_user()

      attrs = %{
        "content" => "chore",
        "process_code" => 0,
        "data" => nil,
        "user_id" => user.id
      }

      conn = post(conn, Routes.notif_path(conn, :create), notif: attrs)
      response = json_response(conn, 200)

      assert response["result"]

      response
      |> Map.get("data")
      |> (fn notification ->
            assert notification["content"] == attrs["content"]
            assert notification["process_code"] == attrs["process_code"]
            assert notification["data"] == attrs["data"]
            assert notification["user_id"] == attrs["user_id"]
          end).()
    end
  end

  describe "delete" do
    # FIXME: assertを追加したい
    test "works", %{conn: conn} do
      user = fixture_user()

      attrs = %{
        "content" => "chore",
        "process_code" => 0,
        "data" => nil,
        "user_id" => user.id
      }

      conn = post(conn, Routes.notif_path(conn, :create), notif: attrs)
      notification = json_response(conn, 200)["data"]

      conn = delete(conn, Routes.notif_path(conn, :delete), id: notification["id"])
      assert json_response(conn, 200)["result"]
    end
  end

  describe "notify all" do
    test "works", %{conn: conn} do
      user1 = fixture_user(1)
      user2 = fixture_user(2)

      text = "test notification text"
      conn = post(conn, Routes.notif_path(conn, :notify_all), text: text)
      assert json_response(conn, 200)["result"]

      conn = get(conn, Routes.notif_path(conn, :get_list), user_id: user1.id)

      json_response(conn, 200)
      |> Map.get("data")
      |> Enum.map(fn notification ->
        assert notification["content"] == text
        assert notification["user_id"] == user1.id
        assert notification["process_code"] == 0
      end)
      |> length()
      |> (fn len ->
            assert len == 1
          end).()

      conn = get(conn, Routes.notif_path(conn, :get_list), user_id: user2.id)

      json_response(conn, 200)
      |> Map.get("data")
      |> Enum.map(fn notification ->
        assert notification["content"] == text
        assert notification["user_id"] == user2.id
        assert notification["process_code"] == 0
      end)
      |> length()
      |> (fn len ->
            assert len == 1
          end).()
    end
  end

  describe "check all" do
    test "works", %{conn: conn} do
      user = fixture_user()

      set_notifications(user.id, 10)

      Notif.list_notification(user.id)
      |> Enum.map(fn notification ->
        assert notification.user_id == user.id
        refute notification.is_checked
      end)
      |> length()
      |> (fn len ->
        assert len == 10
      end).()

      conn = post(conn, Routes.notif_path(conn, :check_all), user_id: user.id)
      json_response(conn, 200)

      Notif.list_notification(user.id)
      |> Enum.map(fn notification ->
        assert notification.user_id == user.id
        assert notification.is_checked
      end)
      |> length()
      |> (fn len ->
        assert len == 10
      end).()
    end
  end
end

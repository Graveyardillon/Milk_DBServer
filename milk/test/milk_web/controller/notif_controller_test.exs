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
        "title" => "chore: #{n}",
        "body_text" => "body #{n}",
        "process_id" => "COMMON",
        "data" => nil,
        "user_id" => user_id
      }
      |> Notif.create_notification()
      |> elem(1)
    end)

    [
      %{
        "user_id" => user_id,
        "title" => "chore",
        "body_text" => "body body body",
        "data" => nil,
        "process_id" => "COMMON"
      },
      %{
        "user_id" => user_id,
        "title" => "ビバンダム君",
        "body_text" => "body body body",
        "data" => nil,
        "process_id" => "COMMON"
      },
      %{
        "user_id" => user_id,
        "title" => "ライブ",
        "body_text" => "body body body",
        "data" => nil,
        "process_id" => "COMMON"
      },
      %{
        "user_id" => user_id,
        "title" => "ビバンダム君",
        "body_text" => "body body body",
        "data" => nil,
        "process_id" => "COMMMON"
      },
      %{
        "user_id" => user_id,
        "title" => "ビバンダム君",
        "body_text" => "TESTからチャット受信",
        "data" => nil,
        "process_id" => "RECEIVED_CHAT"
      },
      %{
        "user_id" => user_id,
        "title" => "ビバンダム君",
        "body_text" => "body body body",
        "data" => nil,
        "process_id" => "FOLLOWING_USER_PLANNED_TOURNAMENT",
        "icon_path" => "./static/image/tournament_thumbnail/2pimp.jpg"
      },
      %{
        "user_id" => user_id,
        "title" => "大会開始",
        "body_text" => "body body body",
        "data" => nil,
        "process_id" => "TOURNAMENT_START",
        "icon_path" => "2pimp"
      },
      %{
        "user_id" => user_id,
        "title" => "重複",
        "body_text" => "body body body",
        "data" => nil,
        "process_id" => "DUPLICATE_CLAIM"
      }
    ]
    |> Enum.each(fn notification ->
      Notif.create_notification(notification)
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
          "title" => "chore",
          "process_id" => "COMMON",
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
        assert notification["title"] == "chore"
        assert notification["process_id"] == "COMMON"
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
        "title" => "chore",
        "process_id" => "COMMON",
        "data" => nil,
        "user_id" => user.id
      }

      conn = post(conn, Routes.notif_path(conn, :create), notif: attrs)
      response = json_response(conn, 200)

      assert response["result"]

      response
      |> Map.get("data")
      |> (fn notification ->
            assert notification["title"] == attrs["title"]
            assert notification["process_id"] == attrs["process_id"]
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
        "title" => "chore",
        "process_id" => "COMMON",
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
        assert notification["title"] == text
        assert notification["user_id"] == user1.id
        assert notification["process_id"] == "COMMON"
      end)
      |> length()
      |> (fn len ->
            assert len == 1
          end).()

      conn = get(conn, Routes.notif_path(conn, :get_list), user_id: user2.id)

      json_response(conn, 200)
      |> Map.get("data")
      |> Enum.map(fn notification ->
        assert notification["title"] == text
        assert notification["user_id"] == user2.id
        assert notification["process_id"] == "COMMON"
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

      conn = get(conn, Routes.notif_path(conn, :get_list), user_id: user.id)

      json_response(conn, 200)
      |> Map.get("data")
      |> Enum.map(fn notification ->
        assert notification["user_id"] == user.id
        refute notification["is_checked"]
      end)
      |> length()
      |> (fn len ->
            assert len == 17
          end).()

      conn = post(conn, Routes.notif_path(conn, :check_all), user_id: user.id)
      assert json_response(conn, 200)["result"]

      conn = get(conn, Routes.notif_path(conn, :get_list), user_id: user.id)

      json_response(conn, 200)
      |> Map.get("data")
      |> Enum.map(fn notification ->
        assert notification["user_id"] == user.id
        assert notification["is_checked"]
      end)
      |> length()
      |> (fn len ->
            assert len == 17
          end).()
    end
  end
end

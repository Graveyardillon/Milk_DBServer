defmodule MilkWeb.NotifControllerTest do
  use MilkWeb.ConnCase

  alias Milk.{
    Accounts,
    Notif
  }

  @create_user_attrs %{"icon_path" => "some icon_path", "language" => "some language", "name" => "some name", "notification_number" => 42, "point" => 42, "email" => "some2@email.com", "logout_fl" => true, "password" => "S1ome password"}

  defp fixture_user() do
    {:ok, user} = Accounts.create_user(@create_user_attrs)
    user
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
end

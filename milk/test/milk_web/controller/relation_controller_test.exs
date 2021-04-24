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
end

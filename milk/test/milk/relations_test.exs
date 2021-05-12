defmodule Milk.RelationsTest do
  use Milk.DataCase

  alias Milk.{
    Accounts,
    Relations
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

  describe "block and blocked users" do
    test "works" do
      user1 = fixture_user(1)
      user2 = fixture_user(2)

      assert {:ok, _block_relation} = Relations.block(user1.id, user2.id)

      Relations.blocked_users(user1.id)
      |> Enum.map(fn block_relation ->
        assert block_relation.block_user_id == user1.id
        assert block_relation.blocked_user_id == user2.id
      end)
      |> length()
      |> (fn len ->
            assert len == 1
          end).()
    end
  end

  describe "unblock" do
    test "works" do
      user1 = fixture_user(1)
      user2 = fixture_user(2)

      {:ok, _} = Relations.block(user1.id, user2.id)
      assert {:ok, _} = Relations.unblock(user1.id, user2.id)
      assert Relations.blocked_users(user1.id) == []
    end
  end
end

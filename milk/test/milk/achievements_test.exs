defmodule Milk.AchievementsTest do
  use Milk.DataCase
  alias Milk.{Accounts, Achievements}
  @user_valid_attrs %{"icon_path" => "some icon_path",
    "language" => "some language", "name" => "some name",
    "notification_number" => 42, "point" => 42,
    "email" => "some@email.com",
    "logout_fl" => true,
    "password" => "S1ome password"}

  describe "achievements" do
    setup [:create_user]
    test "get_achievement/1 returns user's achievements", %{user: user} do
      assert Achievements.get_achievement(user)
    end
  end

  defp create_user(_) do
    {:ok, user} =
      %{}
      |> Enum.into(@user_valid_attrs)
      |> Accounts.create_user()

    %{user:  Accounts.get_user(user.id)}
  end
end

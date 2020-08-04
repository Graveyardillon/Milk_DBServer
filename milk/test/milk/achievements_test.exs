defmodule Milk.AchievementsTest do
  use Milk.DataCase

  alias Milk.Achievements

  describe "achievements" do
    alias Milk.Achievements.Achievement

    @valid_attrs %{icon_path: "some icon_path", title: "some title", user_id: "some user_id"}
    @update_attrs %{icon_path: "some updated icon_path", title: "some updated title", user_id: "some updated user_id"}
    @invalid_attrs %{icon_path: nil, title: nil, user_id: nil}

    def achievement_fixture(attrs \\ %{}) do
      {:ok, achievement} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Achievements.create_achievement()

      achievement
    end

    test "list_achievements/0 returns all achievements" do
      achievement = achievement_fixture()
      assert Achievements.list_achievements() == [achievement]
    end

    test "get_achievement!/1 returns the achievement with given id" do
      achievement = achievement_fixture()
      assert Achievements.get_achievement!(achievement.id) == achievement
    end

    test "create_achievement/1 with valid data creates a achievement" do
      assert {:ok, %Achievement{} = achievement} = Achievements.create_achievement(@valid_attrs)
      assert achievement.icon_path == "some icon_path"
      assert achievement.title == "some title"
      assert achievement.user_id == "some user_id"
    end

    test "create_achievement/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Achievements.create_achievement(@invalid_attrs)
    end

    test "update_achievement/2 with valid data updates the achievement" do
      achievement = achievement_fixture()
      assert {:ok, %Achievement{} = achievement} = Achievements.update_achievement(achievement, @update_attrs)
      assert achievement.icon_path == "some updated icon_path"
      assert achievement.title == "some updated title"
      assert achievement.user_id == "some updated user_id"
    end

    test "update_achievement/2 with invalid data returns error changeset" do
      achievement = achievement_fixture()
      assert {:error, %Ecto.Changeset{}} = Achievements.update_achievement(achievement, @invalid_attrs)
      assert achievement == Achievements.get_achievement!(achievement.id)
    end

    test "delete_achievement/1 deletes the achievement" do
      achievement = achievement_fixture()
      assert {:ok, %Achievement{}} = Achievements.delete_achievement(achievement)
      assert_raise Ecto.NoResultsError, fn -> Achievements.get_achievement!(achievement.id) end
    end

    test "change_achievement/1 returns a achievement changeset" do
      achievement = achievement_fixture()
      assert %Ecto.Changeset{} = Achievements.change_achievement(achievement)
    end
  end
end

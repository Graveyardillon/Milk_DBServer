defmodule Milk.NotifLogTest do
  use Milk.DataCase

  alias Milk.Log

  describe "notification_log" do
    alias Milk.Log.NotificationLog

    @valid_attrs %{title: "some title", user_id: 42}
    @update_attrs %{title: "some updated title", user_id: 43}
    @invalid_attrs %{title: nil, user_id: nil}

    def notification_log_fixture(attrs \\ %{}) do
      {:ok, notification_log} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Log.create_notification_log()

      notification_log
    end

    test "create_notification_log/1 with valid data creates a notification_log" do
      assert {:ok, %NotificationLog{} = notification_log} =
               Log.create_notification_log(@valid_attrs)

      assert notification_log.title == "some title"
      assert notification_log.user_id == 42
    end

    test "create_notification_log/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Log.create_notification_log(@invalid_attrs)
    end

    test "update_notification_log/2 with valid data updates the notification_log" do
      notification_log = notification_log_fixture()

      assert {:ok, %NotificationLog{} = notification_log} =
               Log.update_notification_log(notification_log, @update_attrs)

      assert notification_log.title == "some updated title"
      assert notification_log.user_id == 43
    end

    test "delete_notification_log/1 deletes the notification_log" do
      notification_log = notification_log_fixture()
      assert {:ok, %NotificationLog{}} = Log.delete_notification_log(notification_log)
      assert_raise Ecto.NoResultsError, fn -> Log.get_notification_log!(notification_log.id) end
    end

    test "change_notification_log/1 returns a notification_log changeset" do
      notification_log = notification_log_fixture()
      assert %Ecto.Changeset{} = Log.change_notification_log(notification_log)
    end
  end
end

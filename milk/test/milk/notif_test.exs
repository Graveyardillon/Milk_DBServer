defmodule Milk.NotifTest do
  use Milk.DataCase

  alias Milk.Notif
  alias Milk.Accounts

  describe "notification" do
    alias Milk.Notif.Notification

    @valid_attrs %{"content" => "some content"}
    @update_attrs %{ "content" => "some updated content"}
    @invalid_attrs %{"user_id" => -1, "content" => nil}

    def notification_fixture(attrs \\ %{}) do
      {:ok, user} = Accounts.create_user(%{"name" => "name", "email" => "e@mail.com", "password" => "Password123"})
      {:ok, notification} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Map.put("user_id", user.id)
        |> Notif.create_notification()

      notification
    end

    test "create_notification/1 with valid data creates a notification" do
      {:ok, user} = Accounts.create_user(%{"name" => "name", "email" => "e@mail.com", "password" => "Password123"})
      assert {:ok, %Notification{} = notification} =
        @valid_attrs
        |> Map.put("user_id", user.id)
        |> Notif.create_notification()
      assert notification.content == "some content"
    end

    test "create_notification/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Notif.create_notification(@invalid_attrs)
    end

    test "update_notification/2 with valid data updates the notification" do
      notification = notification_fixture()
      assert {:ok, %Notification{} = notification} = Notif.update_notification(notification, @update_attrs)
      assert notification.content == "some updated content"
    end
    #FIXME: 時間の型とアソシエーション
    # test "update_notification/2 with invalid data returns error changeset" do
    #   notification = notification_fixture()
    #   assert {:error, %Ecto.Changeset{}} = Notif.update_notification(notification, @invalid_attrs)
    #   assert notification == Notif.get_notification!(notification.id)
    # end

    test "delete_notification/1 deletes the notification" do
      notification = notification_fixture()
      assert {:ok, %Notification{}} = Notif.delete_notification(notification)
      assert_raise Ecto.NoResultsError, fn -> Notif.get_notification!(notification.id) end
    end

    test "change_notification/1 returns a notification changeset" do
      notification = notification_fixture()
      assert %Ecto.Changeset{} = Notif.change_notification(notification)
    end
  end
end

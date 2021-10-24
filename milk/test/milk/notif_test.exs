defmodule Milk.NotifTest do
  use Milk.DataCase

  alias Milk.{
    Notif,
    Accounts
  }

  alias Milk.Notif.Notification

  @valid_attrs %{"title" => "some title"}
  @update_attrs %{"title" => "some updated title"}
  @invalid_attrs %{"user_id" => -1, "title" => nil}

  defp notification_fixture(attrs \\ %{}) do
    {:ok, user} =
      Accounts.create_user(%{
        "name" => "name",
        "email" => "e@mail.com",
        "password" => "Password123"
      })

    {:ok, notification} =
      attrs
      |> Enum.into(@valid_attrs)
      |> Map.put("user_id", user.id)
      |> Notif.create_notification()

    notification
  end

  describe "list notification" do
    test "works" do
      {:ok, user} =
        Accounts.create_user(%{
          "name" => "name",
          "email" => "e@mail.com",
          "password" => "Password123"
        })

      Enum.each(1..4, fn _n ->
        %{"title" => "some title"}
        |> Map.put("user_id", user.id)
        |> Notif.create_notification()
      end)

      Notif.list_notifications(user.id)
      |> Enum.map(fn notif ->
        assert notif.user_id == user.id
      end)
      |> length()
      |> (fn len ->
            assert len == 4
          end).()
    end
  end

  describe "unchecked notifications" do
    test "unchecked_notifications/1 works with 0 unchecked notifications" do
      {:ok, user} =
        Accounts.create_user(%{
          "name" => "name",
          "email" => "e@mail.com",
          "password" => "Password123"
        })

      Enum.each(1..4, fn _n ->
        %{"title" => "some title", "is_checked" => true}
        |> Map.put("user_id", user.id)
        |> Notif.create_notification()
      end)

      user.id
      |> Notif.unchecked_notifications()
      |> Enum.map(fn notif ->
        assert notif.user_id == user.id
      end)
      |> length()
      |> (fn len ->
            assert len == 0
          end).()
    end

    test "unchecked_notifications/1 works with 4 unchecked notifications" do
      {:ok, user} =
        Accounts.create_user(%{
          "name" => "name",
          "email" => "e@mail.com",
          "password" => "Password123"
        })

      Enum.each(1..4, fn _n ->
        %{"title" => "some title"}
        |> Map.put("user_id", user.id)
        |> Notif.create_notification()
      end)

      user.id
      |> Notif.unchecked_notifications()
      |> Enum.map(fn notif ->
        assert notif.user_id == user.id
      end)
      |> length()
      |> (fn len ->
            assert len == 4
          end).()
    end
  end

  describe "count unchecked notifications" do
    test "works with 0 unchecked notifications" do
      {:ok, user} =
        Accounts.create_user(%{
          "name" => "name",
          "email" => "e@mail.com",
          "password" => "Password123"
        })

      Enum.each(1..4, fn _n ->
        %{"title" => "some title", "is_checked" => true}
        |> Map.put("user_id", user.id)
        |> Notif.create_notification()
      end)

      user.id
      |> Notif.count_unchecked_notifications()
      |> Kernel.==(0)
      |> assert()
    end

    test "works with 4 unchecked notifications" do
      {:ok, user} =
        Accounts.create_user(%{
          "name" => "name",
          "email" => "e@mail.com",
          "password" => "Password123"
        })

      Enum.each(1..4, fn _n ->
        %{"title" => "some title"}
        |> Map.put("user_id", user.id)
        |> Notif.create_notification()
      end)

      user.id
      |> Notif.count_unchecked_notifications()
      |> Kernel.==(4)
      |> assert()
    end
  end

  describe "notification" do
    test "create_notification/1 with valid data creates a notification" do
      {:ok, user} =
        Accounts.create_user(%{
          "name" => "name",
          "email" => "e@mail.com",
          "password" => "Password123"
        })

      assert {:ok, %Notification{} = notification} =
               @valid_attrs
               |> Map.put("user_id", user.id)
               |> Notif.create_notification()

      assert notification.title == "some title"
    end

    test "create_notification/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Notif.create_notification(@invalid_attrs)
    end

    test "update_notification/2 with valid data updates the notification" do
      notification = notification_fixture()

      assert {:ok, %Notification{} = notification} =
               Notif.update_notification(notification, @update_attrs)

      assert notification.title == "some updated title"
    end

    test "delete_notification/1 deletes the notification" do
      notification = notification_fixture()
      assert {:ok, %Notification{}} = Notif.delete_notification(notification)
      assert_raise Ecto.NoResultsError, fn -> Notif.get_notification!(notification.id) end
    end
  end

  describe "push notification" do
    test "ios" do
      hostname = Common.Tools.get_hostname()
      token = "dummy"

      %Maps.PushIos{
        user_id: 1,
        device_token: token,
        process_id: "COMMON",
        title: "Test",
        message: "Test Notification (#{hostname})"
      }
      |> Milk.Notif.push_ios()
      |> (fn notification ->
            assert notification.device_token == token
            assert notification.push_type == "alert"
            refute is_nil(notification.response)
            assert notification.topic == Notif.topic()
          end).()
    end
  end
end

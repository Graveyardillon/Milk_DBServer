defmodule Milk.Notif do
  @moduledoc """
  The Notif context.
  """

  import Ecto.Query, warn: false
  import Pigeon.APNS.Notification

  alias Maps

  alias Milk.Accounts
  alias Milk.Accounts.User
  alias Milk.Log.NotificationLog
  alias Milk.Repo
  alias Milk.Notif.Notification

  def topic, do: "PapillonKK.e-players"

  @doc """
  Returns the list of notification.

  ## Examples

      iex> list_notification()
      [%Notification{}, ...]

  """
  def list_notification(user_id) do
    Repo.all(
      from n in Notification,
        join: u in assoc(n, :user),
        where: u.id == ^user_id,
        order_by: n.create_time,
        preload: [user: u]
    )
  end

  @doc """
  Get unchecked notifications.
  """
  def unchecked_notifications(user_id) do
    user_id
    |> list_notification()
    |> Enum.filter(fn notification ->
      !notification.is_checked
    end)
  end

  @doc """
  Count unchecked notifications.
  """
  def count_unchecked_notifications(user_id) do
    Notification
    |> where([n], not n.is_checked)
    |> where([n], n.user_id == ^user_id)
    |> Repo.aggregate(:count)
  end

  @doc """
  Gets a single notification.

  Raises `Ecto.NoResultsError` if the Notification does not exist.

  ## Examples

      iex> get_notification!(123)
      %Notification{}

      iex> get_notification!(456)
      ** (Ecto.NoResultsError)

  """
  def get_notification!(id), do: Repo.get!(Notification, id)

  @doc """
  Creates a notification.

  ## Examples

      iex> create_notification(%{field: value})
      {:ok, %Notification{}}

      iex> create_notification(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_notification(attrs \\ %{}) do
    data =
      attrs["data"]
      |> is_nil()
      |> unless do
        if is_integer(attrs["data"]) do
          to_string(attrs["data"])
        else
          attrs["data"]
        end
      end

    attrs = Map.put(attrs, "data", data)

    attrs["user_id"]
    |> Accounts.get_user()
    |> case do
      %User{} = user ->
        Ecto.build_assoc(user, :notif)
        |> Notification.changeset(attrs)
        |> Repo.insert()
        |> case do
          {:ok, notif} -> {:ok, Map.put(notif, :user, Accounts.get_user(attrs["user_id"]))}
          {:error, error} -> {:error, error}
        end

      _ ->
        {:error, %Ecto.Changeset{}}
    end
  end

  @doc """
  Updates a notification.

  ## Examples

      iex> update_notification(notification, %{field: new_value})
      {:ok, %Notification{}}

      iex> update_notification(notification, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_notification(%Notification{} = notification, attrs) do
    notification
    |> Notification.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a notification.

  ## Examples

      iex> delete_notification(notification)
      {:ok, %Notification{}}

      iex> delete_notification(notification)
      {:error, %Ecto.Changeset{}}

  """
  def delete_notification(%Notification{} = notification) do
    %NotificationLog{}
    |> NotificationLog.changeset(Map.from_struct(notification))
    |> Repo.insert()

    Repo.delete(notification)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking notification changes.

  ## Examples

      iex> change_notification(notification)
      %Ecto.Changeset{data: %Notification{}}

  """
  def change_notification(%Notification{} = notification, attrs \\ %{}) do
    Notification.changeset(notification, attrs)
  end

  @doc """
  Creates a notification log.
  """
  def create_notification_log(attrs \\ %{}) do
    %NotificationLog{}
    |> NotificationLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Send push notification to iOS device.
  """
  def push_ios(%Maps.PushIos{} = push_ios) do
    badge_num = count_unchecked_notifications(push_ios.user_id)

    Pigeon.APNS.Notification.new("push_notice", push_ios.device_token, topic())
    |> put_sound("default")
    |> put_badge(badge_num)
    |> put_category(push_ios.process_id)
    |> put_alert(
      Map.merge(%{"body" => push_ios.message, "title" => push_ios.title}, push_ios.params)
    )
    |> put_content_available
    |> put_mutable_content
    |> Pigeon.APNS.push()
  end

  def push_ios_with_badge(msg, title, user_id, device_token) do
    badge_num = count_unchecked_notifications(user_id)

    msg
    |> Pigeon.APNS.Notification.new(device_token, topic())
    |> Pigeon.APNS.Notification.put_alert(%{"body" => msg, "title" => title})
    |> Pigeon.APNS.Notification.put_badge(badge_num)
    |> Pigeon.APNS.push()
  end
end

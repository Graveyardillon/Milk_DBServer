defmodule Milk.Notif do
  @moduledoc """
  The Notif context.
  """

  import Ecto.Query, warn: false
  alias Milk.Repo

  alias Milk.Notif.Notification
  alias Milk.Accounts
  alias Milk.Log.NotificationLog

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
      preload: [user: u]
    )
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
    Accounts.get_user(attrs["user_id"])
    |> Ecto.build_assoc(:notif)
    |> Notification.changeset(attrs)
    |> Repo.insert()
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
    NotificationLog.changeset(%Notification{}, Map.from_struct(notification))
    |> Repo.insert
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
end

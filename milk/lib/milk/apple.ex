defmodule Milk.Apple do
  @moduledoc """
  The Apple Context.
  """

  alias Milk.Apple.User, as: AppleUser
  alias Milk.Repo

  import Ecto.Query, warn: false

  def apple_user_exists?(apple_id) do
    AppleUser
    |> where([au], au.apple_id == ^apple_id)
    |> Repo.exists?()
  end

  @doc """
  Get user by apple id.
  """
  def get_apple_user_by_apple_id(apple_id) do
    AppleUser
    |> where([au], au.apple_id == ^apple_id)
    |> Repo.one()
  end

  @doc """
  Create a apple user.
  """
  def create_apple_user(attrs) do
    %AppleUser{}
    |> AppleUser.changeset(attrs)
    |> Repo.insert()
  end
end

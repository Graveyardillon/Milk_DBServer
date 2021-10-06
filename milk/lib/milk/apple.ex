defmodule Milk.Apple do
  @moduledoc """
  The Apple Context.
  """

  alias Milk.Apple.User, as: AppleUser
  alias Milk.Repo

  import Ecto.Query, warn: false

  @doc """
  Create a apple user.
  """
  def create_apple_user(attrs) do
    %AppleUser{}
    |> AppleUser.changeset(attrs)
    |> Repo.insert()
  end
end

defmodule Milk.Accounts.Profile do
  @moduledoc """
  Profileのスキーマ
  """
  use Milk.Schema

  import Ecto.Changeset

  schema "profiles" do
    field :content_id, :integer
    field :content_type, :string
    field :user_id, :integer

    timestamps()
  end

  @doc false
  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:user_id, :content_id, :content_type])
    |> validate_required([:user_id, :content_id, :content_type])
  end
end

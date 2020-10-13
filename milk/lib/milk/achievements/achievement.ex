defmodule Milk.Achievements.Achievement do
  use Milk.Schema
  import Ecto.Changeset

  alias Milk.Accounts.User

  schema "achievements" do
    field :icon_path, :string
    field :title, :string
    # field :user_id, :string
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(achievement, attrs) do
    achievement
    # |> cast(attrs, [:user_id, :title, :icon_path])
    # |> validate_required([:user_id, :title, :icon_path])
    |> cast(attrs, [:title, :icon_path])
    |> validate_required([:user_id, :title, :icon_path])
  end
end

defmodule Milk.Discord.User do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Accounts.User

  schema "discord_users" do
    # NOTE: 入る数字は整数だけど、あまりに数字が大きいのでstringを選んだ
    field :discord_id, :string

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(discord_user, attrs) do
    discord_user
    |> cast(attrs, [:discord_id, :user_id])
    |> validate_required([:discord_id, :user_id])
  end
end

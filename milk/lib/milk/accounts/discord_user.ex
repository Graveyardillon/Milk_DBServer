defmodule Milk.Accounts.DiscordUser do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Accounts.User

  schema "discord_user" do
    # 入る数字は整数だけどサイズの問題があってstringにした
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

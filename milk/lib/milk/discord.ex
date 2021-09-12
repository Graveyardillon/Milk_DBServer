defmodule Milk.Discord do
  @moduledoc """
  The Discord context.
  """

  alias Milk.Discord.User, as: DiscordUser

  alias Milk.Repo

  import Ecto.Query, warn: false

  def create_discord_user(attrs) do
    %DiscordUser{}
    |> DiscordUser.changeset(attrs)
    |> Repo.insert()
  end

  def associated?(user_id) do
    DiscordUser
    |> where([du], du.user_id == ^user_id)
    |> Repo.exists?()
  end

  def associate(user_id, discord_id) do
    # 同じuser_id discord_idでassociateしていればalready associated
    # user_idだけいけてればupdate
    # どちらもダメならinsert
  end
end

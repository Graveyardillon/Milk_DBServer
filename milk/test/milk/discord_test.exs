defmodule Milk.DiscordTest do
  use Milk.DataCase
  use Common.Fixtures

  import Common.Sperm

  alias Milk.Discord

  describe "create_discord_user" do
    test "works" do
      user = fixture_user()

      %{user_id: user.id, discord_id: "282394857623948"}
      |> Discord.create_discord_user()
      ~> {:ok, discord_user}

      assert discord_user.user_id == user.id
    end
  end
end

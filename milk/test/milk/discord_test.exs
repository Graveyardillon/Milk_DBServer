defmodule Milk.DiscordTest do
  use Milk.DataCase
  use Common.Fixtures

  import Common.Sperm

  alias Milk.Discord

  describe "get_discord_user_by_user_id_and_discord_id" do
    test "works" do
      discord_user = fixture_discord_user()

      du = Discord.get_discord_user_by_user_id_and_discord_id(discord_user.user_id, discord_user.discord_id)
      assert du.user_id == discord_user.user_id
      assert du.discord_id == discord_user.discord_id
    end
  end

  describe "create_discord_user" do
    test "works" do
      user = fixture_user()

      %{user_id: user.id, discord_id: "282394857623948"}
      |> Discord.create_discord_user()
      ~> {:ok, discord_user}

      assert discord_user.user_id == user.id
    end
  end

  describe "associated?" do
    test "works" do
      discord_user = fixture_discord_user()
      user = fixture_user(num: 2)

      assert Discord.associated?(discord_user.user_id)
      refute Discord.associated?(user.id)
    end
  end
end

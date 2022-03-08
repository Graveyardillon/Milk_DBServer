defmodule Milk.DiscordTest do
  use Milk.DataCase
  use Common.Fixtures

  import Common.Sperm

  alias Milk.{
    Discord,
    Tournaments
  }

  describe "get_discord_user_by_user_id_and_discord_id" do
    test "works" do
      discord_user = fixture_discord_user()

      du =
        Discord.get_discord_user_by_user_id_and_discord_id(
          discord_user.user_id,
          discord_user.discord_id
        )

      assert du.user_id == discord_user.user_id
      assert du.discord_id == discord_user.discord_id
    end
  end

  describe "all_team_members_associated?" do
    test "does not work" do
      tournament = fixture_tournament(is_team: true, capacity: 4, type: 2)

      tournament
      |> Map.get(:id)
      |> fill_with_team()
      |> Enum.map(fn team ->
        team
        |> Map.get(:id)
        |> Discord.all_team_members_associated?()
        |> refute()
      end)
    end

    test "works" do
      2..21
      |> Enum.to_list()
      |> Enum.map(fn n ->
        fixture_discord_user(num: n)
      end)
      ~> discord_users

      tournament = fixture_tournament(is_team: true, num: 1)

      discord_users
      |> Enum.map(fn discord_user ->
        discord_user.user_id
      end)
      |> Enum.chunk_every(tournament.team_size)
      |> Enum.map(fn [leader | members] ->
        tournament
        |> Map.get(:id)
        |> Tournaments.create_team(tournament.team_size, leader, members)
        |> elem(1)
      end)
      |> Enum.map(fn team ->
        team
        |> Map.get(:id)
        |> Tournaments.load_team_members_by_team_id()
        |> Enum.each(fn member ->
          leader = Tournaments.get_leader(member.team_id)

          member.id
          |> Tournaments.create_team_invitation(leader.user_id)
          |> elem(1)
          |> Map.get(:id)
          |> Tournaments.confirm_team_invitation()
          |> elem(1)
        end)

        Tournaments.get_team(team.id)
      end)
      |> Enum.map(fn team ->
        assert Discord.all_team_members_associated?(team.id)
      end)
      |> length()
      |> Kernel.==(4)
      |> assert()
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

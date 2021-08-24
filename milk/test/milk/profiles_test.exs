defmodule Milk.ProfilesTest do
  use Milk.DataCase
  use Common.Fixtures

  import Common.Sperm

  alias Milk.{
    TournamentProgress,
    Tournaments
  }

  describe "get records" do
    test "works (both team and individual)" do
      it = fixture_tournament(capacity: 2, type: 2)
      tt = fixture_tournament(is_team: true, type: 2, capacity: 2, num: 2)

      me = fixture_user(num: 3)

      Map.new()
      |> Map.put("user_id", me.id)
      |> Map.put("tournament_id", it.id)
      |> Tournaments.create_entrant()

      4..12
      |> Enum.to_list()
      |> Enum.map(fn n ->
        fixture_user(num: n)
      end)
      ~> members

      [me | members]
      |> Enum.map(fn user -> user.id end)
      |> Enum.chunk_every(tt.team_size)
      |> Enum.map(fn [leader | members] ->
        tt.id
        |> Tournaments.create_team(tt.team_size, leader, members)
        |> elem(1)
      end)
      |> Enum.map(fn team ->
        team.id
        |> Tournaments.get_team_members_by_team_id()
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

      # ~> [my_team | [opponent_team]]

      # TODO: テスト記述
      # 大会を終了させてレコードが出るか見る
    end
  end
end

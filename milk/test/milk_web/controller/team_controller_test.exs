defmodule MilkWeb.TeamControllerTest do
  use MilkWeb.ConnCase
  use Milk.Common.Fixtures

  alias Milk.Tournaments

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  defp setup_team(n) do
    tournament = fixture_tournament([is_started: false, is_team: true])
    users = 1..n
      |> Enum.to_list()
      |> Enum.map(fn n ->
        fixture_user(num: n)
      end)
      |> Enum.map(fn user ->
        user.id
      end)

    [leader | members] = users
    size = n

    tournament.id
    |> Tournaments.create_team(size, leader, members)
    |> (fn {:ok, team} ->
      assert team.tournament_id == tournament.id
      assert team.size == size
    end).()

    {tournament, users}
  end

  describe "get_confirmed_teams" do
    test "works", %{conn: conn} do
      {tournament, users} = setup_team(5)
      [leader | members] = users

      conn = get(conn, Routes.team_path(conn, :get_confirmed_teams), tournament_id: tournament.id)
      json_response(conn, 200)
      |> Map.get("data")
      |> length()
      |> Kernel.==(0)
      |> assert()

      team = tournament.id
        |> Tournaments.get_teams_by_tournament_id()
        |> hd()

      team.id
      |> Tournaments.get_team_members_by_team_id()
      |> Enum.each(fn member ->
        Tournaments.create_team_invitation(member.id, leader, "test")
      end)

      users
      |> Enum.map(fn user_id ->
        user_id
        |> Tournaments.get_team_invitations_by_user_id()
        |> hd()
        |> Map.get(:id)
        |> Tournaments.confirm_team_invitation()
        |> elem(1)
      end)

      conn = get(conn, Routes.team_path(conn, :get_confirmed_teams), tournament_id: tournament.id)
      json_response(conn, 200)
      |> Map.get("data")
      |> length()
      |> Kernel.==(1)
      |> assert()
    end
  end
end

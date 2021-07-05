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

  describe "create_team" do
    test "works", %{conn: conn} do
      tournament = fixture_tournament()
      size = 5
      leader_id = fixture_user(num: 1)
      user_id_list = 2..5
        |> Enum.to_list()
        |> Enum.map(fn n ->
          user = fixture_user(num: n)
          user.id
        end)

      conn = post(
        conn,
        Routes.team_path(conn, :create),
        tournament_id: tournament.id,
        size: size,
        leader_id: leader_id,
        user_id_list: user_id_list
      )

      json_response(conn, 200)
      |> Map.get("data")
      |> (fn data ->
        assert data["tournament_id"] == tournament.id
        assert data["size"] == size
      end).()
    end
  end

  describe "get_confirmed_teams & convirm_invitation" do
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
      |> Enum.each(fn user_id ->
        id = user_id
          |> Tournaments.get_team_invitations_by_user_id()
          |> hd()
          |> Map.get(:id)

        conn = post(conn, Routes.team_path(conn, :confirm_invitation), invitation_id: id)
        assert json_response(conn, 200)["result"]
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

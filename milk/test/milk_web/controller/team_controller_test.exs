defmodule MilkWeb.TeamControllerTest do
  use MilkWeb.ConnCase
  use Common.Fixtures

  import Common.Sperm

  alias Milk.Tournaments

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  defp setup_team(n) do
    tournament = fixture_tournament(is_started: false, is_team: true)

    users =
      1..n
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

  describe "show" do
    test "works", %{conn: conn} do
      tournament = fixture_tournament(is_team: true, type: 2, capacity: 2)

      fill_with_team(tournament.id)
      |> Enum.each(fn team ->
        conn = get(conn, Routes.team_path(conn, :show), team_id: team.id)
        assert json_response(conn, 200)["result"]
        team = json_response(conn, 200)["data"]
        assert Map.has_key?(team, "id")
        assert Map.has_key?(team, "name")
        assert Map.has_key?(team, "size")
        assert Map.has_key?(team, "team_member")
        assert Map.has_key?(team, "tournament_id")

        team
        |> Map.get("team_member")
        |> Enum.map(fn member ->
          assert Map.has_key?(member, "id")
          assert member["is_invitation_confirmed"]
          assert Map.has_key?(member, "is_leader")
          assert Map.has_key?(member, "team_id")
          assert Map.has_key?(member, "user")
          assert Map.has_key?(member, "user_id")
          user = member["user"]
          assert Map.has_key?(user, "email")
          assert Map.has_key?(user, "bio")
          assert Map.has_key?(user, "icon_path")
          assert Map.has_key?(user, "name")
        end)
      end)
    end
  end

  describe "get_teammates" do
    test "works", %{conn: conn} do
      tournament = fixture_tournament()
      size = 5
      leader_id = fixture_user(num: 1).id

      user_id_list =
        2..5
        |> Enum.to_list()
        |> Enum.map(fn n ->
          user = fixture_user(num: n)
          user.id
        end)

      conn =
        post(
          conn,
          Routes.team_path(conn, :create),
          tournament_id: tournament.id,
          size: size,
          leader_id: leader_id,
          user_id_list: user_id_list
        )

      conn =
        get(conn, Routes.team_path(conn, :get_teammates),
          tournament_id: tournament.id,
          user_id: leader_id
        )

      json_response(conn, 200)
      |> Map.get("data")
      |> Enum.map(fn member ->
        assert member["user_id"] in user_id_list || member["user_id"] == leader_id
      end)
      |> length()
      |> Kernel.==(5)
      |> assert()
    end
  end

  describe "create_team" do
    test "works", %{conn: conn} do
      tournament = fixture_tournament()
      size = 5
      leader_id = fixture_user(num: 1).id

      user_id_list =
        2..5
        |> Enum.to_list()
        |> Enum.map(fn n ->
          user = fixture_user(num: n)
          user.id
        end)

      conn =
        post(
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

      assert json_response(conn, 200)["result"]
    end

    test "over tournament size", %{conn: conn} do
      tournament = fixture_tournament(capacity: 1)

      leader_id = fixture_user(num: 1).id

      user_id_list =
        2..5
        |> Enum.to_list()
        |> Enum.map(fn n ->
          user = fixture_user(num: n)
          user.id
        end)

      conn =
        post(
          conn,
          Routes.team_path(conn, :create),
          tournament_id: tournament.id,
          size: 5,
          leader_id: leader_id,
          user_id_list: user_id_list
        )

      assert json_response(conn, 200)["result"]
      team = json_response(conn, 200)["data"]

      team["id"]
      |> Tournaments.get_team_members_by_team_id()
      |> Enum.each(fn member ->
        Tournaments.create_team_invitation(member.id, leader_id)
      end)

      user_id_list
      |> Enum.map(fn user_id ->
        user_id
        |> Tournaments.get_team_invitations_by_user_id()
        |> hd()
        |> Map.get(:id)
        |> Tournaments.confirm_team_invitation()
        |> elem(1)
      end)

      leader_id = fixture_user(num: 6)

      user_id_list =
        7..10
        |> Enum.to_list()
        |> Enum.map(fn n ->
          user = fixture_user(num: n)
          user.id
        end)

      conn =
        post(
          conn,
          Routes.team_path(conn, :create),
          tournament_id: tournament.id,
          size: 5,
          leader_id: leader_id,
          user_id_list: user_id_list
        )

      assert json_response(conn, 200)["error"] == "over tournament size"
    end
  end

  describe "get_confirmed_teams & convirm_invitation" do
    test "works", %{conn: conn} do
      {tournament, users} = setup_team(5)
      [leader | _members] = users

      conn = get(conn, Routes.team_path(conn, :get_confirmed_teams), tournament_id: tournament.id)

      json_response(conn, 200)
      |> Map.get("data")
      |> length()
      |> Kernel.==(0)
      |> assert()

      tournament.id
      |> Tournaments.get_teams_by_tournament_id()
      |> hd()
      ~> team

      team.id
      |> Tournaments.get_team_members_by_team_id()
      |> Enum.each(fn member ->
        Tournaments.create_team_invitation(member.id, leader)
      end)

      users
      |> Enum.reverse()
      |> hd()
      ~> tail_user_id

      users
      |> Enum.each(fn user_id ->
        user_id
        |> Tournaments.get_team_invitations_by_user_id()
        |> hd()
        |> Map.get(:id)
        ~> id

        conn = post(conn, Routes.team_path(conn, :confirm_invitation), invitation_id: id)
        assert json_response(conn, 200)["result"]
        assert json_response(conn, 200)["tournament_id"] == tournament.id

        if user_id == tail_user_id do
          assert json_response(conn, 200)["is_confirmed"]
        else
          refute json_response(conn, 200)["is_confirmed"]
        end
      end)

      conn = get(conn, Routes.team_path(conn, :get_confirmed_teams), tournament_id: tournament.id)

      json_response(conn, 200)
      |> Map.get("data")
      |> length()
      |> Kernel.==(1)
      |> assert()
    end
  end

  describe "delete" do
    test "works", %{conn: conn} do
      {tournament, _users} = setup_team(5)

      team =
        tournament.id
        |> Tournaments.get_teams_by_tournament_id()
        |> hd()

      conn = get(conn, Routes.team_path(conn, :show), team_id: team.id)
      json_response(conn, 200)

      conn = delete(conn, Routes.team_path(conn, :delete), team_id: team.id)
      assert json_response(conn, 200)["result"]

      conn = get(conn, Routes.team_path(conn, :show), team_id: team.id)
      refute json_response(conn, 200)["result"]
    end
  end
end

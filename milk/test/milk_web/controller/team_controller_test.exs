defmodule MilkWeb.TeamControllerTest do
  @moduledoc """
  Team Controller test.
  """
  use Common.Fixtures
  use MilkWeb.ConnCase

  import Common.Sperm

  alias Milk.{
    Notif,
    Tournaments
  }

  @moduletag timeout: 300_000

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  defp setup_team(n) do
    tournament = fixture_tournament(is_started: false, is_team: true, team_size: n)

    1..n
    |> Enum.to_list()
    |> Enum.map(fn n ->
      fixture_user(num: n)
    end)
    |> Enum.map(fn user ->
      user.id
    end)
    ~> users

    [leader | members] = users
    size = n

    tournament.id
    |> Tournaments.create_team(size, leader, members)
    |> then(fn {:ok, team} ->
      assert team.tournament_id == tournament.id
      assert team.size == size
    end)

    {tournament, users}
  end

  describe "show" do
    test "works both /1 and /2", %{conn: conn} do
      tournament = fixture_tournament(is_team: true, type: 2, capacity: 2)

      tournament.id
      |> fill_with_team()
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

        leader = Tournaments.get_leader(team["id"])
        conn = get(conn, Routes.team_path(conn, :show), tournament_id: tournament.id, user_id: leader.user_id)
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

  describe "teams" do
    test "works", %{conn: conn} do
      tournament = fixture_tournament(is_team: true)
      fill_with_team(tournament.id)

      conn = get(conn, Routes.team_path(conn, :get_teams), tournament_id: tournament.id)

      assert json_response(conn, 200)["result"]

      conn
      |> json_response(200)
      |> Map.get("data")
      |> Enum.map(fn team ->
        assert team["is_confirmed"]
      end)
      |> Enum.empty?()
      |> refute()
    end
  end

  describe "get_teammates" do
    test "works", %{conn: conn} do
      tournament = fixture_tournament(is_team: true)
      size = 5
      leader_id = fixture_user(num: 1).id

      2..5
      |> Enum.to_list()
      |> Enum.map(fn n ->
        user = fixture_user(num: n)
        user.id
      end)
      ~> user_id_list

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
      tournament = fixture_tournament(is_team: true)
      size = 5
      leader_id = fixture_user(num: 1).id

      2..5
      |> Enum.to_list()
      |> Enum.map(fn n ->
        user = fixture_user(num: n)
        user.id
      end)
      ~> user_id_list

      conn =
        post(
          conn,
          Routes.team_path(conn, :create),
          tournament_id: tournament.id,
          size: size,
          leader_id: leader_id,
          user_id_list: user_id_list
        )

      conn
      |> json_response(200)
      |> Map.get("data")
      |> then(fn data ->
        assert data["tournament_id"] == tournament.id
        assert data["size"] == size
      end)

      assert json_response(conn, 200)["result"]

      # NOTE: 通知が作成されているかどうかの確認
      user_id_list
      |> Enum.each(fn user_id ->
        conn
        |> get(Routes.notif_path(conn, :get_list), %{"user_id" => user_id})
        |> json_response(200)
        |> Map.get("data")
        |> Enum.map(fn notification ->
          assert notification["user_id"] == user_id
          #assert String.contains?(notification["title"], "からチーム招待されました")
          assert notification["process_id"] == "TEAM_INVITE"
        end)
        |> length()
        |> then(fn len ->
          assert len != 0
        end)
      end)
    end

    test "works with name", %{conn: conn} do
      tournament = fixture_tournament(is_team: true)
      size = 5
      leader_id = fixture_user(num: 1).id

      2..5
      |> Enum.to_list()
      |> Enum.map(fn n ->
        user = fixture_user(num: n)
        user.id
      end)
      ~> user_id_list

      conn =
        post(
          conn,
          Routes.team_path(conn, :create),
          tournament_id: tournament.id,
          size: size,
          leader_id: leader_id,
          user_id_list: user_id_list,
          name: "super team name"
        )

      conn
      |> json_response(200)
      |> Map.get("data")
      |> then(fn data ->
        assert data["tournament_id"] == tournament.id
        assert data["size"] == size
        assert data["name"] == "super team name"
      end)

      assert json_response(conn, 200)["result"]

      # NOTE: 通知が作成されているかどうかの確認
      user_id_list
      |> Enum.each(fn user_id ->
        conn
        |> get(Routes.notif_path(conn, :get_list), %{"user_id" => user_id})
        |> json_response(200)
        |> Map.get("data")
        |> Enum.map(fn notification ->
          assert notification["user_id"] == user_id
          #assert String.contains?(notification["title"], "からチーム招待されました")
          assert notification["process_id"] == "TEAM_INVITE"
        end)
        |> length()
        |> then(fn len ->
          assert len != 0
        end)
      end)
    end

    test "works with nil name", %{conn: conn} do
      tournament = fixture_tournament(is_team: true)
      size = 5
      leader_id = fixture_user(num: 1).id

      2..5
      |> Enum.to_list()
      |> Enum.map(fn n ->
        user = fixture_user(num: n)
        user.id
      end)
      ~> user_id_list

      conn =
        post(
          conn,
          Routes.team_path(conn, :create),
          tournament_id: tournament.id,
          size: size,
          leader_id: leader_id,
          user_id_list: user_id_list,
          name: nil
        )

      conn
      |> json_response(200)
      |> Map.get("data")
      |> then(fn data ->
        assert data["tournament_id"] == tournament.id
        assert data["size"] == size
        assert data["name"]
      end)

      assert json_response(conn, 200)["result"]

      # NOTE: 通知が作成されているかどうかの確認
      user_id_list
      |> Enum.each(fn user_id ->
        conn
        |> get(Routes.notif_path(conn, :get_list), %{"user_id" => user_id})
        |> json_response(200)
        |> Map.get("data")
        |> Enum.map(fn notification ->
          assert notification["user_id"] == user_id
          #assert String.contains?(notification["title"], "からチーム招待されました")
          assert notification["process_id"] == "TEAM_INVITE"
        end)
        |> length()
        |> then(fn len ->
          assert len != 0
        end)
      end)
    end

    test "over tournament size", %{conn: conn} do
      tournament = fixture_tournament(capacity: 1, is_team: true)
      leader_id = fixture_user(num: 1).id

      2..5
      |> Enum.to_list()
      |> Enum.map(fn n ->
        user = fixture_user(num: n)
        user.id
      end)
      ~> user_id_list

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
      |> Tournaments.load_team_members_by_team_id()
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
      |> Tournaments.load_team_members_by_team_id()
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

      conn
      |> json_response(200)
      |> Map.get("data")
      |> length()
      |> Kernel.==(1)
      |> assert()

      conn = get(conn, Routes.team_path(conn, :get_confirmed_teams_without_members), tournament_id: tournament.id)

      conn
      |> json_response(200)
      |> Map.get("data")
      |> length()
      |> Kernel.==(1)
      |> assert()
    end
  end

  describe "delete" do
    test "works", %{conn: conn} do
      tournament = fixture_tournament(is_team: true)
      fill_with_team(tournament.id)

      tournament.id
      |> Tournaments.get_teams_by_tournament_id()
      |> hd()
      ~> team

      conn = get(conn, Routes.team_path(conn, :show), team_id: team.id)
      json_response(conn, 200)

      conn = delete(conn, Routes.team_path(conn, :delete), team_id: team.id)
      assert json_response(conn, 200)["result"]

      # conn = get(conn, Routes.team_path(conn, :show), team_id: team.id)
      # refute json_response(conn, 200)["result"]
    end
  end

  describe "add members" do
    test "works", %{conn: conn} do
      tournament = fixture_tournament(is_team: true, capacity: 4, team_size: 5)
      leader = fixture_user(num: 1)
      member = fixture_user(num: 2)
      size = 5

      conn =
        post(
          conn,
          Routes.team_path(conn, :create),
          tournament_id: tournament.id,
          size: size,
          leader_id: leader.id,
          user_id_list: [member.id]
        )

      assert json_response(conn, 200)["result"]
      team_id = json_response(conn, 200)["data"]["id"]

      added_member = fixture_user(num: 3)

      conn =
        post(
          conn,
          Routes.team_path(conn, :add_members),
          team_id: team_id,
          user_id_list: [added_member.id]
        )

      assert json_response(conn, 200)["result"]

      conn = get(conn, Routes.team_path(conn, :show), team_id: team_id)

      conn
      |> json_response(200)
      |> Map.get("data")
      |> Map.get("team_member")
      |> length()
      |> Kernel.==(3)
      |> assert()
    end
  end

  describe "resend team invitations" do
    test "works", %{conn: conn} do
      tournament = fixture_tournament(is_team: true, type: 2, capacity: 2)

      11..(tournament.team_size * tournament.capacity * 10)
      |> Enum.to_list()
      |> Enum.map(&fixture_user(num: &1))
      |> Enum.map(&Map.get(&1, :id))
      ~> all_member_id_list
      |> Enum.chunk_every(tournament.team_size)
      |> Enum.map(fn [leader | members] ->
        tournament.id
        |> Tournaments.create_team(tournament.team_size, leader, members)
        |> elem(1)
      end)
      ~> teams

      all_member_id_list
      |> Enum.map(fn user_id ->
        user_id
        |> Notif.list_notifications()
        |> Enum.each(&Notif.delete_notification(&1))
      end)

      all_member_id_list
      |> Enum.map(&Notif.list_notifications(&1))
      |> List.flatten()
      |> Enum.empty?()
      |> assert()

      Enum.each(teams, fn team ->
        conn = post(conn, Routes.team_path(conn, :resend_team_invitations), team_id: team.id)
        assert json_response(conn, 200)["result"]
      end)

      all_member_id_list
      |> Enum.map(&Notif.list_notifications(&1))
      |> List.flatten()
      |> Enum.empty?()
      |> refute()
    end
  end
end

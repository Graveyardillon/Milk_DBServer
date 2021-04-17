defmodule Milk.TournamentProgressTest do
  @moduledoc """
  Redisが使えるときのみコメントアウトを解除する
  """
  use Milk.DataCase
  use Timex

  alias Milk.{
    Accounts,
    TournamentProgress,
    Tournaments
  }

  @valid_attrs %{
    "capacity" => 42,
    "deadline" => "2010-04-17T14:00:00Z",
    "description" => "some description",
    "event_date" => "2010-04-17T14:00:00Z",
    "name" => "some name",
    "type" => 0,
    "url" => "somesomeurl",
    "master_id" => 1,
    "platform_id" => 1,
    "is_started" => true
  }
  @entrant_create_attrs %{
    "rank" => 42,
    "user_id" => -1,
    "tournament_id" => -1
  }

  @moduletag timeout: :infinity

  defp fixture_tournament(opts \\ []) do
    # FIXME: ここのデフォルト値は本当はfalseのほうがよさそう
    is_started =
      opts[:is_started]
      |> is_nil()
      |> unless do
        opts[:is_started]
      else
        true
      end

    master_id =
      opts[:master_id]
      |> is_nil()
      |> unless do
        opts[:master_id]
      else
        {:ok, user} = Accounts.create_user(%{"name" => "name", "email" => "e@mail.com", "password" => "Password123"})
        user.id
      end

    {:ok, tournament} =
      @valid_attrs
      |> Map.put("is_started", is_started)
      |> Map.put("master_id", master_id)
      |> Tournaments.create_tournament()
    tournament
  end

  defp fixture_entrant(opts \\ %{}) do
    tournament =
      opts["tournament_id"]
      |> is_nil()
      |> unless do
        Tournaments.get_tournament!(opts["tournament_id"])
      else
        fixture_tournament()
      end

    user_id =
      opts["user_id"]
      |> is_nil()
      |> unless do
        opts["user_id"]
      else
        tournament.master_id
      end

    {:ok, entrant} =
      %{@entrant_create_attrs | "tournament_id" => tournament.id, "user_id" => user_id}
      |> Tournaments.create_entrant()
    entrant
  end

  defp create_entrants(num, tournament_id, result \\ []), do: create_entrants(num, tournament_id, result, num)
  defp create_entrants(_num, _tournament_id, result, 0) do
    result
  end

  defp create_entrants(num, tournament_id, result, current) do
    {:ok, user} =
      %{"name" => "name" <> to_string(current), "email" => "e" <> to_string(current) <> "@mail.com", "password" => "Password123"}
      |> Accounts.create_user()
    {:ok, entrant} =
      %{@entrant_create_attrs | "tournament_id" => tournament_id, "user_id" => user.id, "rank" => num}
      |> Tournaments.create_entrant()
    create_entrants(num, tournament_id, (result ++ [entrant]), current - 1)
  end

  defp create_entrant(_) do
    entrant = fixture_entrant()
    %{entrant: entrant}
  end

  defp start(master_id, tournament_id) do
    Tournaments.start(master_id, tournament_id)

    {:ok, match_list} =
      Tournaments.get_entrants(tournament_id)
      |> Enum.map(fn x -> x.user_id end)
      |> Tournaments.generate_matchlist()

    count =
      Tournaments.get_tournament(tournament_id)
      |> Map.get(:count)
    match_list
    |> Tournaments.initialize_rank(count, tournament_id)
    match_list
    |> TournamentProgress.insert_match_list(tournament_id)

    list_with_fight_result =
      match_list
      |> match_list_with_fight_result()

    lis =
      list_with_fight_result
      |> Tournamex.match_list_to_list()

    Enum.reduce(lis, list_with_fight_result, fn x, acc ->
      user = Accounts.get_user(x["user_id"])

      acc
      |> Tournaments.put_value_on_brackets(user.id, %{"name" => user.name})
      |> Tournaments.put_value_on_brackets(user.id, %{"win_count" => 0})
      |> Tournaments.put_value_on_brackets(user.id, %{"icon_path" => user.icon_path})
    end)
    |> TournamentProgress.insert_match_list_with_fight_result(tournament_id)
  end

  defp match_list_with_fight_result(match_list) do
    Tournaments.initialize_match_list_with_fight_result(match_list)
  end

  describe "match list table" do
    test "insert_match_list/2 works fine" do
      match_list = [[1, 2], 3]
      assert r = TournamentProgress.insert_match_list(match_list, 1)
      assert is_boolean(r)
    end

    test "get_match_list/1 works fine" do
      match_list = [[1, 2], 3]
      TournamentProgress.insert_match_list(match_list, 2)
      {tid, match_list} = TournamentProgress.get_match_list(2) |> hd()
      assert tid
      assert match_list
      assert tid == 2
      assert match_list == [[1, 2], 3]
    end

    test "delete_match_list/1 works fine" do
      match_list = [[1, 2], 3]
      TournamentProgress.insert_match_list(match_list, 3)
      assert r = TournamentProgress.delete_match_list(3)
      assert is_boolean(r)
    end
  end

  describe "match pending list" do
    test "insert_match_pending_list_table/1 works fine" do
      r = TournamentProgress.insert_match_pending_list_table({1, 1})
      assert r
      assert is_boolean(r)
    end

    test "get_match_pending_list/2" do
      TournamentProgress.insert_match_pending_list_table({1, 2})
      assert {r} = TournamentProgress.get_match_pending_list({1, 2})|>hd()
      assert r == {1, 2}
    end

    test "delete_match_pending_list" do
      TournamentProgress.insert_match_pending_list_table({1, 3})
      assert r = TournamentProgress.delete_match_pending_list({1, 3})
      assert is_boolean(r)
    end
  end

  describe "fight result table" do
    test "insert_fight_result/2 works fine" do
      assert r = TournamentProgress.insert_fight_result_table({1, 1}, true)
      assert is_boolean(r)
    end

    test "get_fight_result/1 works fine true" do
      TournamentProgress.insert_fight_result_table({1, 2}, true)
      assert {_, r} = TournamentProgress.get_fight_result({1, 2})|>hd()
      assert is_boolean(r)
    end

    test "get_fight_result/1 works fine false" do
      TournamentProgress.insert_fight_result_table({2, 2}, false)
      assert {_, r} = TournamentProgress.get_fight_result({2, 2})|>hd()
      refute r
    end

    test "delete_fight_result/1 works fine" do
      TournamentProgress.insert_fight_result_table({1, 3}, true)
      assert r = TournamentProgress.delete_fight_result({1, 3})
      assert is_boolean(r)
    end
  end

  describe "match list with fight result" do
    test "insert_match_list_with_fight_result/2" do
      match_list = [[1, 2], 3]
      r = TournamentProgress.insert_match_list_with_fight_result(match_list, 1)
      assert r
      assert is_boolean(r)
    end

    test "get_match_list_with_fight_result/1" do
      match_list = [[1, 2], 3]
      TournamentProgress.insert_match_list_with_fight_result(match_list, 2)
      assert {_, r} = TournamentProgress.get_match_list_with_fight_result(2)|>hd()
      assert r == match_list
    end

    test "delete_match_list_with_fight_result/1" do
      match_list = [[1, 2], 3]
      TournamentProgress.insert_match_list_with_fight_result(match_list, 3)
      assert r = TournamentProgress.delete_match_list_with_fight_result(3)
      assert is_boolean(r)
    end
  end

  describe "duplicate users" do
    test "test duplicate user pair" do
      assert TournamentProgress.add_duplicate_user_id(1, 1)
      TournamentProgress.add_duplicate_user_id(1, 2)
      TournamentProgress.add_duplicate_user_id(1, 3)
      assert TournamentProgress.get_duplicate_users(1) == [1, 2, 3]
      assert TournamentProgress.delete_duplicate_user(1, 1)
      assert TournamentProgress.get_duplicate_users(1) == [2, 3]
      assert TournamentProgress.delete_duplicate_users_all(1)
      assert TournamentProgress.get_duplicate_users(1) == []
    end
  end

  describe "set_timelimit" do
    test "set_timelimit_on_all_entrants/1 works fine" do
      tournament = fixture_tournament(is_started: false)
      entrants = create_entrants(7, tournament.id)
      {:ok, entrant} = Tournaments.create_entrant(%{"user_id" => tournament.master_id, "tournament_id" => tournament.id})
      entrants = entrants ++ [entrant]
      start(tournament.master_id, tournament.id)

      [{_, match_list}] = TournamentProgress.get_match_list(tournament.id)
      TournamentProgress.set_time_limit_on_all_entrants(match_list, tournament.id)
      [{_, match_list}] = TournamentProgress.get_match_list(tournament.id)
      refute Tournaments.has_lost?(match_list, tournament.master_id)

      Process.sleep(1000*62*5)
      [{_, match_list}] = TournamentProgress.get_match_list(tournament.id)
      assert Tournaments.has_lost?(match_list, tournament.master_id)
    end
  end
end

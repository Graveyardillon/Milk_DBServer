defmodule Milk.Tournaments.ProgressTest do
  @moduledoc """
  Redisが使えるときのみコメントアウトを解除する
  """
  use Milk.DataCase
  use Common.Fixtures
  use Timex

  alias Milk.{
    Accounts,
    Tournaments
  }

  alias Milk.Tournaments.Progress

  @entrant_create_attrs %{
    "rank" => 42,
    "user_id" => -1,
    "tournament_id" => -1
  }

  @moduletag timeout: :infinity

  defp create_entrants(num, tournament_id, result \\ []),
    do: create_entrants(num, tournament_id, result, num)

  defp create_entrants(_num, _tournament_id, result, 0) do
    result
  end

  defp create_entrants(num, tournament_id, result, current) do
    {:ok, user} =
      %{
        "name" => "name" <> to_string(current),
        "email" => "e" <> to_string(current) <> "@mail.com",
        "password" => "Password123"
      }
      |> Accounts.create_user()

    {:ok, entrant} =
      %{
        @entrant_create_attrs
        | "tournament_id" => tournament_id,
          "user_id" => user.id,
          "rank" => num
      }
      |> Tournaments.create_entrant()

    create_entrants(num, tournament_id, result ++ [entrant], current - 1)
  end

  defp start(master_id, tournament_id) do
    Tournaments.start(tournament_id, master_id)

    {:ok, match_list} =
      Tournaments.get_entrants(tournament_id)
      |> Enum.map(fn x -> x.user_id end)
      |> Tournaments.generate_matchlist()

    count =
      Tournaments.load_tournament(tournament_id)
      |> Map.get(:count)

    match_list
    |> Tournaments.initialize_rank(count, tournament_id)

    match_list
    |> Progress.insert_match_list(tournament_id)

    list_with_fight_result =
      match_list
      |> match_list_with_fight_result()

    lis =
      list_with_fight_result
      |> List.flatten()

    Enum.reduce(lis, list_with_fight_result, fn x, acc ->
      user = Accounts.get_user(x["user_id"])

      acc
      |> Tournaments.put_value_on_brackets(user.id, %{"name" => user.name})
      |> Tournaments.put_value_on_brackets(user.id, %{"win_count" => 0})
      |> Tournaments.put_value_on_brackets(user.id, %{"icon_path" => user.icon_path})
    end)
    |> Progress.insert_match_list_with_fight_result(tournament_id)
  end

  defp match_list_with_fight_result(match_list) do
    Tournaments.initialize_match_list_with_fight_result(match_list)
  end

  describe "match list table" do
    test "insert_match_list/2 works fine" do
      match_list = [[1, 2], 3]
      assert {:ok, nil} = Progress.insert_match_list(match_list, 1)
    end

    test "get_match_list/1 works fine" do
      match_list = [[1, 2], 3]
      Progress.insert_match_list(match_list, 2)
      match_list = Progress.get_match_list(2)
      assert match_list
      assert match_list == [[1, 2], 3]
    end

    test "get_match_list/1 returns data 1 size smaller than past one after deleting a user" do
      tournament = fixture_tournament(is_started: true)
      entrants = create_entrants(8, tournament.id)
      entrant_id_list = Enum.map(entrants, fn entrant -> entrant.user_id end)
      start(tournament.master_id, tournament.id)

      tournament.id
      |> Progress.get_match_list()
      |> List.flatten()
      |> Enum.map(fn user_id ->
        assert user_id in entrant_id_list
      end)
      |> length()
      |> (fn len ->
            assert len == length(entrants)
          end).()

      entrants
      |> hd()
      |> Map.get(:user_id)
      |> Accounts.get_user()
      |> Accounts.delete()

      tournament.id
      |> Progress.get_match_list()
      |> List.flatten()
      |> Enum.map(fn user_id ->
        if user_id == hd(entrants).user_id do
          refute user_id in entrant_id_list
        else
          assert user_id in entrant_id_list
        end
      end)
      |> length()
      |> (fn len ->
            assert len == length(entrants) - 1
          end).()
    end

    test "delete_match_list/1 works fine" do
      match_list = [[1, 2], 3]
      Progress.insert_match_list(match_list, 3)
      assert {:ok, nil} = Progress.delete_match_list(3)
    end
  end

  describe "match pending list" do
    test "insert_match_pending_list_table/1 works fine" do
      tournament = fixture_tournament(is_started: true)
      assert Progress.insert_match_pending_list_table(1, tournament.id)
    end

    test "get_match_pending_list/2" do
      tournament = fixture_tournament(is_started: true)
      Progress.insert_match_pending_list_table(1, tournament.id)

      assert "IsWaitingForStart" == Progress.get_match_pending_list(1, tournament.id)
    end

    test "delete_match_pending_list" do
      tournament = fixture_tournament(is_started: true)
      Progress.insert_match_pending_list_table(1, tournament.id)
      assert {:ok, _} = Progress.delete_match_pending_list(1, tournament.id)
    end
  end

  describe "fight result table" do
    test "insert_fight_result/2 works fine" do
      assert {:ok, _} = Progress.insert_fight_result_table(1, 1, true)
    end

    test "get_fight_result/1 works fine true" do
      Progress.insert_fight_result_table(1, 2, true)
      assert r = Progress.get_fight_result(1, 2)
      assert is_boolean(r)
    end

    test "get_fight_result/1 works fine false" do
      Progress.insert_fight_result_table(2, 2, false)
      r = Progress.get_fight_result(2, 2)
      refute r
    end

    test "delete_fight_result/1 works fine" do
      Progress.insert_fight_result_table(1, 3, true)
      assert {:ok, _} = Progress.delete_fight_result(1, 3)
    end
  end

  describe "match list with fight result" do
    test "insert_match_list_with_fight_result/2" do
      match_list = [
        [
          %{"user_id" => 1},
          %{"user_id" => 2}
        ],
        %{"user_id" => 3}
      ]

      assert {:ok, _} = Progress.insert_match_list_with_fight_result(match_list, 1)
    end

    test "get_match_list_with_fight_result/1" do
      match_list = [
        [
          %{"user_id" => 1},
          %{"user_id" => 2}
        ],
        %{"user_id" => 3}
      ]

      Progress.insert_match_list_with_fight_result(match_list, 2)

      2
      |> Progress.get_match_list_with_fight_result()
      |> (fn result ->
            result == match_list
          end).()
    end

    test "get_match_list/1 returns data which is renewed after deleting a user" do
      tournament = fixture_tournament(is_started: true)
      entrants = create_entrants(8, tournament.id)
      entrant_id_list = Enum.map(entrants, fn entrant -> entrant.user_id end)
      start(tournament.master_id, tournament.id)

      tournament.id
      |> Progress.get_match_list_with_fight_result()
      |> List.flatten()
      |> Enum.map(fn bracket ->
        assert is_map(bracket)

        if is_map(bracket) do
          assert bracket["user_id"] in entrant_id_list
          assert bracket["is_loser"] == false
        end
      end)

      entrants
      |> hd()
      |> Map.get(:user_id)
      |> Accounts.get_user()
      |> Accounts.delete()

      tournament.id
      |> Progress.get_match_list_with_fight_result()
      |> List.flatten()
      |> Enum.map(fn bracket ->
        if is_map(bracket) do
          if bracket["user_id"] == hd(entrants).user_id do
            assert bracket["user_id"] in entrant_id_list
            assert bracket["is_loser"]
          else
            assert bracket["user_id"] in entrant_id_list
            assert bracket["is_loser"] == false
          end
        end
      end)
    end

    test "delete_match_list_with_fight_result/1" do
      match_list = [[1, 2], 3]
      Progress.insert_match_list_with_fight_result(match_list, 3)
      assert {:ok, _} = Progress.delete_match_list_with_fight_result(3)
    end
  end

  describe "duplicate users" do
    test "test duplicate user pair" do
      assert Progress.add_duplicate_user_id(1, 1)
      Progress.add_duplicate_user_id(1, 2)
      Progress.add_duplicate_user_id(1, 3)
      assert Progress.get_duplicate_users(1) == [1, 2, 3]
      assert Progress.delete_duplicate_user(1, 1)
      assert Progress.get_duplicate_users(1) == [2, 3]
      assert Progress.delete_duplicate_users_all(1)
      assert Progress.get_duplicate_users(1) == []
    end
  end

  describe "score table" do
    test "insert_score/3 and get_score/2" do
      tid = 1
      uid = 1
      score = 13
      Progress.insert_score(tid, uid, score)

      assert Progress.get_score(tid, uid) == score
    end
  end

  describe "get single tournament match logs" do
    test "works" do
      user1 = fixture_user(num: 1)
      user2 = fixture_user(num: 2)
      tournament = fixture_tournament(is_started: true)
      str = "just str"

      Map.new()
      |> Map.put("tournament_id", tournament.id)
      |> Map.put("winner_id", user1.id)
      |> Map.put("loser_id", user2.id)
      |> Map.put("match_list_str", str)
      |> Progress.create_single_tournament_match_log()

      Progress.get_single_tournament_match_logs(tournament.id, user1.id)
      |> Enum.map(fn log ->
        assert log.tournament_id == tournament.id
        assert log.winner_id == user1.id
        assert log.loser_id == user2.id
        assert log.match_list_str == str
      end)
      |> length()
      |> (fn len ->
            assert len == 1
          end).()

      Progress.get_single_tournament_match_logs(tournament.id, user2.id)
      |> Enum.map(fn log ->
        assert log.tournament_id == tournament.id
        assert log.winner_id == user1.id
        assert log.loser_id == user2.id
        assert log.match_list_str == str
      end)
      |> length()
      |> (fn len ->
            assert len == 1
          end).()
    end
  end

  describe "create single tournament match log" do
    test "JUST works" do
      user1 = fixture_user(num: 1)
      user2 = fixture_user(num: 2)
      tournament = fixture_tournament(is_started: true)
      str = "just str"

      id =
        %{}
        |> Map.put("tournament_id", tournament.id)
        |> Map.put("winner_id", user1.id)
        |> Map.put("loser_id", user2.id)
        |> Map.put("match_list_str", str)
        |> Progress.create_single_tournament_match_log()
        |> (fn result ->
              assert {:ok, log} = result
              assert log.tournament_id == tournament.id
              assert log.winner_id == user1.id
              assert log.loser_id == user2.id
              assert log.match_list_str == str
              log.id
            end).()

      Progress.get_single_tournament_match_log(id)
      |> (fn log ->
            assert log.tournament_id == tournament.id
            assert log.winner_id == user1.id
            assert log.loser_id == user2.id
            assert log.match_list_str == str
            log.id
          end).()
    end
  end

  describe "create and get match list with fight result log" do
    test "just works" do
      match_list = [[1, 2], [3, 4]]
      tournament_id = 1

      str = inspect(match_list, charlists: false)

      %{"tournament_id" => tournament_id, "match_list_with_fight_result_str" => str}
      |> Progress.create_match_list_with_fight_result_log()
      |> (fn log ->
            assert {:ok, log} = log
            assert log.tournament_id == tournament_id
            assert log.match_list_with_fight_result_str == str
          end).()
    end
  end
end

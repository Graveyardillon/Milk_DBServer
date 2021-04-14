defmodule Milk.TournamentProgressTest do
  @moduledoc """
  Redisが使えるときのみコメントアウトを解除する
  """
  use Milk.DataCase
  use Timex

  alias Milk.{
    TournamentProgress,
    Tournaments
  }

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
      match_list = [[1, 2], 3]
      TournamentProgress.set_time_limit_on_all_entrants(match_list, 1)

    end
  end
end

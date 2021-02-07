defmodule Milk.EtsTest do
  use Milk.DataCase

  alias Milk.Ets

  describe "match list table" do
    test "insert_match_list/2 works fine" do
      match_list = [[1, 2], 3]
      assert r = Ets.insert_match_list(match_list, 1)
      assert is_boolean(r)
    end

    test "get_match_list/1 works fine" do
      match_list = [[1, 2], 3]
      Ets.insert_match_list(match_list, 2)
      {tid, match_list} = Ets.get_match_list(2) |> hd()
      assert tid
      assert match_list
      assert tid == 2
      assert match_list == [[1, 2], 3]
    end

    test "delete_match_list/1 works fine" do
      match_list = [[1, 2], 3]
      Ets.insert_match_list(match_list, 3)
      assert r = Ets.delete_match_list(3)
      assert is_boolean(r)
    end
  end

  describe "match pending list" do
    test "insert_match_pending_list_table/1 works fine" do
      r = Ets.insert_match_pending_list_table({1, 1})
      assert r
      assert is_boolean(r)
    end

    test "get_match_pending_list/2" do
      Ets.insert_match_pending_list_table({1, 2})
      assert {r} = Ets.get_match_pending_list({1, 2})|>hd()
      assert r == {1, 2}
    end

    test "delete_match_pending_list" do
      Ets.insert_match_pending_list_table({1, 3})
      assert r = Ets.delete_match_pending_list({1, 3})
      assert is_boolean(r)
    end
  end

  describe "fight result table" do
    test "insert_fight_result/2 works fine" do
      assert r = Ets.insert_fight_result_table({1, 1}, true)
      assert is_boolean(r)
    end

    test "get_fight_result/1 works fine true" do
      Ets.insert_fight_result_table({1, 2}, true)
      assert {_, r} = Ets.get_fight_result({1, 2})|>hd()
      assert is_boolean(r)
    end

    test "get_fight_result/1 works fine false" do
      Ets.insert_fight_result_table({2, 2}, false)
      assert {_, r} = Ets.get_fight_result({2, 2})|>hd()
      refute r
    end

    test "delete_fight_result/1 works fine" do
      Ets.insert_fight_result_table({1, 3}, true)
      assert r = Ets.delete_fight_result({1, 3})
      assert is_boolean(r)
    end
  end

  describe "match list with fight result" do
    test "insert_match_list_with_fight_result/2" do
      match_list = [[1, 2], 3]
      r = Ets.insert_match_list_with_fight_result(match_list, 1)
      assert r
      assert is_boolean(r)
    end

    test "get_match_list_with_fight_result/1" do
      match_list = [[1, 2], 3]
      Ets.insert_match_list_with_fight_result(match_list, 2)
      assert {_, r} = Ets.get_match_list_with_fight_result(2)|>hd()
      assert r == match_list
    end

    test "delete_match_list_with_fight_result/1" do
      match_list = [[1, 2], 3]
      Ets.insert_match_list_with_fight_result(match_list, 3)
      assert r = Ets.delete_match_list_with_fight_result(3)
      assert is_boolean(r)
    end
  end
end

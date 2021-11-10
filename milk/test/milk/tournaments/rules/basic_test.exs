defmodule Milk.Tournaments.Rules.BasicTest do
  @moduledoc """
  Test for basic rule.
  """
  use Milk.DataCase
  use Common.Fixtures

  alias Milk.Tournaments.Rules
  alias Milk.Tournaments.Rules.Basic

  describe "building dfa" do
    test "just works" do
      Dfa.Instant.flushall()

      user1 = fixture_user(num: 1)
      user2 = fixture_user(num: 2)
      user3 = fixture_user(num: 3)
      user4 = fixture_user(num: 4)
      user5 = fixture_user(num: 5)
      tournament_id = 1
      keyname1 = Rules.adapt_keyname(user1.id, tournament_id)
      keyname2 = Rules.adapt_keyname(user2.id, tournament_id)
      keyname3 = Rules.adapt_keyname(user3.id, tournament_id)
      keyname4 = Rules.adapt_keyname(user4.id, tournament_id)
      keyname5 = Rules.adapt_keyname(user5.id, tournament_id)
      Basic.define_dfa!()
      Basic.build_dfa_instance(keyname1)
      Basic.build_dfa_instance(keyname2)
      Basic.build_dfa_instance(keyname3)
      Basic.build_dfa_instance(keyname4)
      Basic.build_dfa_instance(keyname5)

      # NOTE: startまで
      assert Basic.state!(keyname1) == Basic.is_not_started()
      assert Basic.state!(keyname2) == Basic.is_not_started()
      assert {:ok, _} = Basic.trigger!(keyname1, Basic.start_trigger())
      assert Basic.state!(keyname1) == Basic.should_start_match()
      assert {:ok, _} = Basic.trigger!(keyname2, Basic.start_trigger())
      assert Basic.state!(keyname2) == Basic.should_start_match()
      assert {:ok, _} = Basic.trigger!(keyname3, Basic.manager_trigger())
      assert Basic.state!(keyname3) == Basic.is_manager()
      assert {:ok, _} = Basic.trigger!(keyname4, Basic.member_trigger())
      assert Basic.state!(keyname4) == Basic.is_member()
      assert {:ok, _} = Basic.trigger!(keyname5, Basic.assistant_trigger())
      assert Basic.state!(keyname5) == Basic.is_assistant()

      # NOTE: 対戦終了まで
      assert {:ok, _} = Basic.trigger!(keyname1, Basic.start_match_trigger())
      assert Basic.state!(keyname1) == Basic.is_waiting_for_start_match()
      assert {:ok, _} = Basic.trigger!(keyname2, Basic.start_match_trigger())
      assert Basic.state!(keyname2) == Basic.is_waiting_for_start_match()
      assert {:ok, _} = Basic.trigger!(keyname1, Basic.pend_trigger())
      assert Basic.state!(keyname1) == Basic.is_pending()
      assert {:ok, _} = Basic.trigger!(keyname2, Basic.pend_trigger())
      assert Basic.state!(keyname2) == Basic.is_pending()
      assert {:ok, _} = Basic.trigger!(keyname1, Basic.lose_trigger())
      assert Basic.state!(keyname1) == Basic.is_loser()
      assert {:ok, _} = Basic.trigger!(keyname2, Basic.alone_trigger())
      assert Basic.state!(keyname2) == Basic.is_alone()

      # NOTE: 大会終了
      assert {:ok, _} = Basic.trigger!(keyname1, Basic.finish_trigger())
      assert {:ok, _} = Basic.trigger!(keyname2, Basic.finish_trigger())
      assert Basic.state!(keyname1) == Basic.is_finished()
      assert Basic.state!(keyname2) == Basic.is_finished()
    end
  end
end

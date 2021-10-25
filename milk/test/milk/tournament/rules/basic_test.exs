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
      keyname1 = Rules.adapt_keyname(user1.id)
      keyname2 = Rules.adapt_keyname(user2.id)
      Basic.define_dfa!()
      Basic.build_dfa_instance(keyname1)
      Basic.build_dfa_instance(keyname2)

      # NOTE: startまで
      assert Basic.state!(keyname1) == Basic.is_not_started()
      assert Basic.state!(keyname2) == Basic.is_not_started()
      assert {:ok, _} = Basic.trigger!(keyname1, Basic.start_trigger())
      assert Basic.state!(keyname1) == Basic.should_start_match()
      assert {:ok, _} = Basic.trigger!(keyname2, Basic.start_trigger())
      assert Basic.state!(keyname2) == Basic.should_start_match()

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

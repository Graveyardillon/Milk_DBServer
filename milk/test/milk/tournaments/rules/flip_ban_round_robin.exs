defmodule Milk.Tournaments.Rules.FlipBanRoundRobinTest do
  @moduledoc """
  Test for flip ban round robin rule.
  """
  use Milk.DataCase
  use Common.Fixtures

  alias Milk.Tournaments.Rules
  alias Milk.Tournaments.Rules.FlipBanRoundRobin

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
      FlipBanRoundRobin.define_dfa!()
      FlipBanRoundRobin.build_dfa_instance(keyname1)
      FlipBanRoundRobin.build_dfa_instance(keyname2)
      FlipBanRoundRobin.build_dfa_instance(keyname3)
      FlipBanRoundRobin.build_dfa_instance(keyname4)
      FlipBanRoundRobin.build_dfa_instance(keyname5)

      # NOTE: startまで
      assert FlipBanRoundRobin.state!(keyname1) == FlipBanRoundRobin.is_not_started()
      assert FlipBanRoundRobin.state!(keyname2) == FlipBanRoundRobin.is_not_started()
      assert FlipBanRoundRobin.state!(keyname3) == FlipBanRoundRobin.is_not_started()
      assert FlipBanRoundRobin.state!(keyname4) == FlipBanRoundRobin.is_not_started()
      assert FlipBanRoundRobin.state!(keyname5) == FlipBanRoundRobin.is_not_started()
      assert {:ok, _} = FlipBanRoundRobin.trigger!(keyname1, FlipBanRoundRobin.start_trigger())
      assert FlipBanRoundRobin.state!(keyname1) == FlipBanRoundRobin.should_flip_coin()
      assert {:ok, _} = FlipBanRoundRobin.trigger!(keyname2, FlipBanRoundRobin.start_trigger())
      assert FlipBanRoundRobin.state!(keyname2) == FlipBanRoundRobin.should_flip_coin()
      assert {:ok, _} = FlipBanRoundRobin.trigger!(keyname3, FlipBanRoundRobin.manager_trigger())
      assert FlipBanRoundRobin.state!(keyname3) == FlipBanRoundRobin.is_manager()
      assert {:ok, _} = FlipBanRoundRobin.trigger!(keyname4, FlipBanRoundRobin.member_trigger())
      assert FlipBanRoundRobin.state!(keyname4) == FlipBanRoundRobin.is_member()
      assert {:ok, _} = FlipBanRoundRobin.trigger!(keyname5, FlipBanRoundRobin.assistant_trigger())
      assert FlipBanRoundRobin.state!(keyname5) == FlipBanRoundRobin.is_assistant()

      # NOTE: mapのban完了まで
      assert {:ok, _} = FlipBanRoundRobin.trigger!(keyname1, FlipBanRoundRobin.flip_trigger())
      assert FlipBanRoundRobin.state!(keyname1) == FlipBanRoundRobin.is_waiting_for_coin_flip()
      assert {:error, _} = FlipBanRoundRobin.trigger!(keyname2, FlipBanRoundRobin.ban_map_trigger())
      assert FlipBanRoundRobin.state!(keyname2) == FlipBanRoundRobin.should_flip_coin()
      assert {:ok, _} = FlipBanRoundRobin.trigger!(keyname2, FlipBanRoundRobin.flip_trigger())
      assert FlipBanRoundRobin.state!(keyname2) == FlipBanRoundRobin.is_waiting_for_coin_flip()

      assert {:ok, _} = FlipBanRoundRobin.trigger!(keyname1, FlipBanRoundRobin.ban_map_trigger())
      assert {:ok, _} = FlipBanRoundRobin.trigger!(keyname2, FlipBanRoundRobin.observe_ban_map_trigger())
      assert FlipBanRoundRobin.state!(keyname1) == FlipBanRoundRobin.should_ban_map()
      assert FlipBanRoundRobin.state!(keyname2) == FlipBanRoundRobin.should_observe_ban()

      assert {:error, _} = FlipBanRoundRobin.trigger!(keyname1, FlipBanRoundRobin.ban_map_trigger())
      assert {:ok, _} = FlipBanRoundRobin.trigger!(keyname1, FlipBanRoundRobin.observe_ban_map_trigger())
      assert {:ok, _} = FlipBanRoundRobin.trigger!(keyname2, FlipBanRoundRobin.ban_map_trigger())
      assert FlipBanRoundRobin.state!(keyname1) == FlipBanRoundRobin.should_observe_ban()
      assert FlipBanRoundRobin.state!(keyname2) == FlipBanRoundRobin.should_ban_map()

      assert {:ok, _} = FlipBanRoundRobin.trigger!(keyname1, FlipBanRoundRobin.choose_map_trigger())
      assert {:ok, _} = FlipBanRoundRobin.trigger!(keyname2, FlipBanRoundRobin.observe_choose_map_trigger())
      assert FlipBanRoundRobin.state!(keyname1) == FlipBanRoundRobin.should_choose_map()
      assert FlipBanRoundRobin.state!(keyname2) == FlipBanRoundRobin.should_observe_choose()

      assert {:ok, _} = FlipBanRoundRobin.trigger!(keyname1, FlipBanRoundRobin.observe_choose_ad_trigger())
      assert {:ok, _} = FlipBanRoundRobin.trigger!(keyname2, FlipBanRoundRobin.choose_ad_trigger())
      assert FlipBanRoundRobin.state!(keyname1) == FlipBanRoundRobin.should_observe_ad()
      assert FlipBanRoundRobin.state!(keyname2) == FlipBanRoundRobin.should_choose_ad()

      assert {:ok, _} = FlipBanRoundRobin.trigger!(keyname1, FlipBanRoundRobin.pend_trigger())
      assert {:ok, _} = FlipBanRoundRobin.trigger!(keyname2, FlipBanRoundRobin.pend_trigger())
      assert FlipBanRoundRobin.state!(keyname1) == FlipBanRoundRobin.is_pending()
      assert FlipBanRoundRobin.state!(keyname2) == FlipBanRoundRobin.is_pending()

      assert {:ok, _} = FlipBanRoundRobin.trigger!(keyname1, FlipBanRoundRobin.waiting_for_score_input_trigger())
      assert FlipBanRoundRobin.state!(keyname1) == FlipBanRoundRobin.is_waiting_for_score_input()

      assert {:ok, _} = FlipBanRoundRobin.trigger!(keyname1, FlipBanRoundRobin.next_trigger())
      assert {:ok, _} = FlipBanRoundRobin.trigger!(keyname2, FlipBanRoundRobin.next_trigger())
      assert FlipBanRoundRobin.state!(keyname1) == FlipBanRoundRobin.should_flip_coin()
      assert FlipBanRoundRobin.state!(keyname2) == FlipBanRoundRobin.should_flip_coin()

      # NOTE: 大会終了
      assert {:ok, _} = FlipBanRoundRobin.trigger!(keyname1, FlipBanRoundRobin.finish_trigger())
      assert {:ok, _} = FlipBanRoundRobin.trigger!(keyname2, FlipBanRoundRobin.finish_trigger())
      assert FlipBanRoundRobin.state!(keyname1) == FlipBanRoundRobin.is_finished()
      assert FlipBanRoundRobin.state!(keyname2) == FlipBanRoundRobin.is_finished()
    end
  end
end

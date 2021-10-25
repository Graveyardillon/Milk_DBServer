defmodule Milk.Tournaments.Rules.FlipBanTest do
  @moduledoc """
  Test for flip and ban rule.
  """
  use Milk.DataCase
  use Common.Fixtures

  alias Milk.Tournaments.Rules
  alias Milk.Tournaments.Rules.FlipBan

  describe "building dfa" do
    test "just works" do
      Dfa.Instant.flushall()

      user1 = fixture_user(num: 1)
      user2 = fixture_user(num: 2)
      keyname1 = Rules.adapt_keyname(user1.id)
      keyname2 = Rules.adapt_keyname(user2.id)
      FlipBan.define_dfa()
      FlipBan.build_dfa_instance(keyname1)
      FlipBan.build_dfa_instance(keyname2)

      # NOTE: startまで
      assert FlipBan.state!(keyname1) == FlipBan.is_not_started()
      assert FlipBan.state!(keyname2) == FlipBan.is_not_started()
      assert {:ok, _} = FlipBan.trigger!(keyname1, FlipBan.start_trigger())
      assert FlipBan.state!(keyname1) == FlipBan.should_flip_coin()
      assert {:ok, _} = FlipBan.trigger!(keyname2, FlipBan.start_trigger())
      assert FlipBan.state!(keyname2) == FlipBan.should_flip_coin()

      # NOTE: mapのban完了まで
      assert {:ok, _} = FlipBan.trigger!(keyname1, FlipBan.flip_trigger())
      assert FlipBan.state!(keyname1) == FlipBan.is_waiting_for_coin_flip()
      assert {:error, _} = FlipBan.trigger!(keyname2, FlipBan.ban_map_trigger())
      assert FlipBan.state!(keyname2) == FlipBan.should_flip_coin()
      assert {:ok, _} = FlipBan.trigger!(keyname2, FlipBan.flip_trigger())
      assert FlipBan.state!(keyname2) == FlipBan.is_waiting_for_coin_flip()

      assert {:ok, _} = FlipBan.trigger!(keyname1, FlipBan.ban_map_trigger())
      assert {:ok, _} = FlipBan.trigger!(keyname2, FlipBan.observe_ban_map_trigger())
      assert FlipBan.state!(keyname1) == FlipBan.should_ban_map()
      assert FlipBan.state!(keyname2) == FlipBan.should_observe_ban()

      assert {:error, _} = FlipBan.trigger!(keyname1, FlipBan.ban_map_trigger())
      assert {:ok, _} = FlipBan.trigger!(keyname1, FlipBan.observe_ban_map_trigger())
      assert {:ok, _} = FlipBan.trigger!(keyname2, FlipBan.ban_map_trigger())
      assert FlipBan.state!(keyname1) == FlipBan.should_observe_ban()
      assert FlipBan.state!(keyname2) == FlipBan.should_ban_map()

      assert {:ok, _} = FlipBan.trigger!(keyname1, FlipBan.choose_map_trigger())
      assert {:ok, _} = FlipBan.trigger!(keyname2, FlipBan.observe_choose_map_trigger())
      assert FlipBan.state!(keyname1) == FlipBan.should_choose_map()
      assert FlipBan.state!(keyname2) == FlipBan.should_observe_choose()

      assert {:ok, _} = FlipBan.trigger!(keyname1, FlipBan.observe_choose_ad_trigger())
      assert {:ok, _} = FlipBan.trigger!(keyname2, FlipBan.choose_ad_trigger())
      assert FlipBan.state!(keyname1) == FlipBan.should_observe_ad()
      assert FlipBan.state!(keyname2) == FlipBan.should_choose_ad()

      assert {:ok, _} = FlipBan.trigger!(keyname1, FlipBan.pend_trigger())
      assert {:ok, _} = FlipBan.trigger!(keyname2, FlipBan.pend_trigger())
      assert FlipBan.state!(keyname1) == FlipBan.is_pending()
      assert FlipBan.state!(keyname2) == FlipBan.is_pending()

      assert {:ok, _} = FlipBan.trigger!(keyname1, FlipBan.lose_trigger())
      assert {:ok, _} = FlipBan.trigger!(keyname2, FlipBan.alone_trigger())
      assert FlipBan.state!(keyname1) == FlipBan.is_loser()
      assert FlipBan.state!(keyname2) == FlipBan.is_alone()

      # NOTE: 大会終了
      assert {:ok, _} = FlipBan.trigger!(keyname1, FlipBan.finish_trigger())
      assert {:ok, _} = FlipBan.trigger!(keyname2, FlipBan.finish_trigger())
      assert FlipBan.state!(keyname1) == FlipBan.is_finished()
      assert FlipBan.state!(keyname2) == FlipBan.is_finished()
    end
  end
end

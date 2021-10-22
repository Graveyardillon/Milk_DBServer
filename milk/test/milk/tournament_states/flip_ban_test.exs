defmodule Milk.TournamentStates.FlipBanTest do
  use Milk.DataCase
  use Common.Fixtures

  alias Milk.TournamentStates.FlipBan

  describe "building dfa" do
    test "just works" do
      Dfa.Instant.flushall()

      user1 = fixture_user(num: 1)
      user2 = fixture_user(num: 2)
      keyname1 = "user:#{user1.id}"
      keyname2 = "user:#{user2.id}"
      machine_name = "flipban"
      FlipBan.define_dfa(machine_name)
      FlipBan.build_dfa_instance(keyname1, machine_name)
      FlipBan.build_dfa_instance(keyname2, machine_name)

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

      assert {:ok, _} = FlipBan.trigger!(keyname1, FlipBan.finish_trigger())
      assert {:ok, _} = FlipBan.trigger!(keyname2, FlipBan.finish_trigger())
      assert FlipBan.state!(keyname1) == FlipBan.is_finished()
      assert FlipBan.state!(keyname2) == FlipBan.is_finished()
    end
  end
end

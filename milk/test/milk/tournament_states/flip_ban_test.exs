defmodule Milk.TournamentStates.FlipBanTest do
  use Milk.DataCase
  use Common.Fixtures

  alias Milk.TournamentStates.FlipBan

  describe "building dfa" do
    test "just works" do
      Dfa.flushall()

      user = fixture_user()
      keyname1 = "user:#{user.id}"
      FlipBan.build_dfa(keyname1)

      assert FlipBan.state!(keyname1) == FlipBan.is_not_started()
    end
  end
end

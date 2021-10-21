defmodule Milk.TournamentStates.FlipBanTest do
  use Milk.DataCase

  alias Milk.TournamentStates.FlipBan

  describe "building dfa" do
    test "just works" do
      Dfa.flushall()
      FlipBan.build_dfa("seed")
    end
  end
end

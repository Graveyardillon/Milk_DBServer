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
      machine_name = Basic.machine_name()
    end
  end
end

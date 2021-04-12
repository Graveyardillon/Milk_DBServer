defmodule Milk.TournamentProgressTest do
  use ExUnit.Case

  alias Milk.TournamentProgress

  describe "duplicate users" do
    test "test duplicate user pair" do
      assert TournamentProgress.add_duplicate_user_id(1, 1)
      TournamentProgress.add_duplicate_user_id(1, 2)
      TournamentProgress.add_duplicate_user_id(1, 3)
      assert TournamentProgress.get_duplicate_users(1) == ["1", "2", "3"]
      assert TournamentProgress.delete_duplicate_user(1, 1)
      assert TournamentProgress.get_duplicate_users(1) == ["2", "3"]
      assert TournamentProgress.delete_duplicate_users_all(1)
      assert TournamentProgress.get_duplicate_users(1) == []
    end
  end
end

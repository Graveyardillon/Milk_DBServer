defmodule Milk.Tournaments.EntriesTest do
  @moduledoc """
  エントリーに関するテスト
  """
  use Milk.DataCase
  use Common.Fixtures

  alias Milk.Tournaments.Entries

  describe "create entry template and its information" do
    test "just works" do
      tournament = fixture_tournament()

      entry_template = [
        %{tournament_id: tournament.id, title: "お名前"},
        %{tournament_id: tournament.id, title: "RiotID 1"},
        %{tournament_id: tournament.id, title: "RiotID 2"},
        %{tournament_id: tournament.id, title: "RiotID 3"},
        %{tournament_id: tournament.id, title: "RiotID 4"},
        %{tournament_id: tournament.id, title: "RiotID 5"}
      ]

      Enum.each(entry_template, fn template ->
        assert {:ok, _} = Entries.create_entry_template(template)
      end)

      entry_information_list = [
        %{title: "お名前",    field: "name one"},
        %{title: "RiotID 1", field: "asdf#12312"},
        %{title: "RiotID 2", field: "asdfas#123"},
        %{title: "RiotID 3", field: "asdfff#5654"},
        %{title: "RiotID 4", field: "aslkjlj#098"},
        %{title: "RiotID 5", field: "lakjsdf#984"}
      ]

      user = fixture_user()

      assert {:ok, _} = Entries.create_entry(entry_information_list, tournament.id, user.id)
    end
  end
end

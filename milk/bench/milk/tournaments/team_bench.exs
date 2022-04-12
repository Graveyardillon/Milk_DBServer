defmodule Milk.Tournaments.TeamBench do
  @moduledoc """
  get_teamの性能テスト
  """
  use Benchfella
  use Common.Fixtures

  alias Milk.Tournaments

  setup_all do
    result = Application.ensure_all_started(:milk)
    user = fixture_user()
    tournament = fixture_tournament(master_id: user.id, is_team: true)
    fill_with_team(tournament.id)
    result
  end
  teardown_all _, do: Application.stop(:milk)

  bench "get_team" do
    1..128
    |> Enum.to_list()
    |> Enum.each(fn _ ->
      Tournaments.get_team(1)
    end)
  end

  bench "load_team" do
    1..128
    |> Enum.to_list()
    |> Enum.each(fn _ ->
      Tournaments.load_team(1)
    end)
  end
end

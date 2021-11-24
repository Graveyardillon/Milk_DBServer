defmodule Milk.TournamentsBench do
  @moduledoc """
  Tournamets.exの性能テスト
  """
  use Benchfella
  use Common.Fixtures

  alias Milk.Tournaments

  @tournament_list Enum.to_list(1..128)

  setup_all       do: Application.ensure_all_started(:milk)
  teardown_all _, do: Application.stop(:milk)

  bench "get_tournament", [t: tournaments] do
    t
    |> Map.get(&Map.get(&1, :id))
    |> Enum.each(&Tournaments.get_tournament(&1))
  end

  defp tournaments() do
    Enum.map(@tournament_list, &fixture_tournament(num: &1))
  end
end

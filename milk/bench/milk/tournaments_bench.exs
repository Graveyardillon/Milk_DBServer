defmodule Milk.TournamentsBench do
  @moduledoc """
  Tournamets.exの性能テスト
  """
  use Benchfella
  use Common.Fixtures

  alias Milk.Tournaments

  @tournament_list Enum.to_list(1..128)

  setup_all       do
    result = Application.ensure_all_started(:milk)
    fixture_user()
    result
  end
  teardown_all _, do: Application.stop(:milk)

  bench "get_tournament", [t: tournaments] do
    Enum.each(t, &Tournaments.get_tournament(&1))
  end

  bench "load_tournament",[t: tournaments] do
    Enum.each(t, &Tournaments.load_tournament(&1))
  end

  defp tournaments() do
    @tournament_list
    |> Enum.map(&fixture_tournament(num: &1, master_id: 1))
    |> Enum.map(&(&1.id))
  end
end

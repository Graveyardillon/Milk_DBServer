defmodule Milk.Tournaments.MatchInfoBench do
  @moduledoc """
  match_infoのbench
  """
  use Benchfella
  use Common.Fixtures

  alias Milk.Tournaments
  alias Milk.Tournaments.Progress

  setup_all do
    result = Application.ensure_all_started(:milk)

    tournament = fixture_tournament(is_team: true)
    fill_with_team(tournament.id)

    Progress.start_team_best_of_format(tournament.master_id, tournament)
    result
  end
  teardown_all _, do: Application.stop(:milk)

  bench "get_match_info" do
    1..128
    |> Enum.to_list()
    |> Enum.each(fn _ ->
      Tournaments.get_match_information(1, 2)
    end)
  end

  bench "new get_match_info" do
    1..128
    |> Enum.to_list()
    |> Enum.each(fn _ ->

    end)
  end
end

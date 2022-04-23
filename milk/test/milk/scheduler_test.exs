defmodule Milk.SchedulerTest do
  use Common.Fixtures
  use Milk.DataCase

  alias Milk.Tournaments.{
    Tournament
  }
  alias Milk.{
    Scheduler,
    Repo
  }

  describe "finish_tournaments_a_week_ago" do

    test "finish_tournaments_a_week_ago/0 finish tournaments" do
      user = fixture_user()

      fixture_tournament()

      Tournament
      |> Repo.all
      |> IO.inspect()

      Scheduler.finish_tournaments_a_week_ago()
      Tournament
      |> Repo.all
      |> Kernel.==([])
      |> assert
    end

    test "finish_tournaments_a_week_ago/0 finish three tournament" do
      user = fixture_user()

      fixture_tournament()
      dont_deleted = fixture_tournament([event_date: "2022-04-17T14:00:00Z",master_id: user.id])
      fixture_tournament([event_date: Timex.now()
      |> Timex.add(Timex.Duration.from_days(-7))
      |> Timex.to_datetime(),master_id: user.id])
      fixture_tournament([event_date: Timex.now()
      |> Timex.add(Timex.Duration.from_days(-8))
      |> Timex.to_datetime(),master_id: user.id])
      six_from_now = fixture_tournament([event_date: Timex.now()
      |> Timex.add(Timex.Duration.from_days(-6))
      |> Timex.to_datetime(),master_id: user.id])

      # Tournament
      # |> Repo.all
      # |> IO.inspect()

      Scheduler.finish_tournaments_a_week_ago()
      Tournament
      |> Repo.all
      |> IO.inspect(label: :pickup)
      |> Enum.map(fn x -> x.id end)
      |> Kernel.==([dont_deleted.id, six_from_now.id])
      |> assert
    end
  end
end

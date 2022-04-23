defmodule Milk.Scheduler do
  use Quantum,
    otp_app: :milk
  use Timex
  import Ecto.Query, warn: false

  alias Milk.Tournaments.{
    Tournament
  }
  alias Milk.{
    Repo,
    Tournaments
  }

  def finish_tournaments_a_week_ago do
    threshold_date =
      Timex.now()
      |> Timex.add(Timex.Duration.from_days(-7))
      |> Timex.to_datetime()

    Tournament
    |> where([t], t.event_date < ^threshold_date)
    |> Repo.all()
    |> Enum.each(fn x -> Tournaments.finish(x.id, 0) end)
  end
end

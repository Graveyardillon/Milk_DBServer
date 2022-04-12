defmodule Milk.Scheduler do
  use Quantum.Scheduler,
    otp_app :milk
  use Timex

  alias Milk.Tournaments.{
    Tournament
  }

  def finish_tournaments_a_week_ago do
    Timex.now
    Map.update!(:day,
      fn day ->
        case day + 7 do
          x when x < 30 -> x
          x -> x - 29
        end
      end)
    ~> threshold_date

  end
end

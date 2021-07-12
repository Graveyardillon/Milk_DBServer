defmodule Oban.Processer do
  use Oban.Worker, queue: :default

  alias Milk.{
    Accounts,
    Notif,
    Tournaments
  }

  @impl Oban.Worker
  
  def perform(%Oban.Job{args: args}) do
    IO.puts("start processing job...")

    case args do
      %{"notify_tournament_start" => id} ->
        notify_tournament_start(id)
      _ ->
        IO.puts("undefined arg")
    end

    IO.puts("...finished job")
  end 

  defp notify_tournament_start(id) do
    tournament = Tournaments.get_tournament(id)
    if tournament do 
      devices = 
        for entrant <- Map.get(tournament, :entrant) do
          Accounts.get_devices_by_user_id(entrant.user_id)
        end
        |> List.flatten()
      # IO.inspect(devices)

      for device <- devices do
        Notif.push_ios("トーナメント開始", device.token, 1, "")
      end
    else
        IO.puts("tournament not found")
    end
  end
end
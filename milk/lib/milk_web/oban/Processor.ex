defmodule Oban.Processer do
  use Oban.Worker, queue: :default

  alias Milk.{
    Accounts,
    Notif,
    Tournaments
  }

  @impl Oban.Worker

  def perform(%Oban.Job{args: args}) do
   # TODO: 通知に大会情報などを含めたい
    case args do
      %{"reminder_to_start_tournament" => id} ->
        reminder_to_start_tournament(id)
      _ ->
        IO.puts("undefined arg")
    end
  end

  defp reminder_to_start_tournament(id) do
    tournament = Tournaments.get_tournament(id)
    params = %{tournament_id: id}
    devices = Accounts.get_devices_by_user_id(tournament.master_id)

    for device <- devices do
      Notif.push_ios(
        device.user_id,
        device.token,
        6,
        tournament.name,
        "主催している大会の開始予定時刻になりました。大会を開始してください！",
        params
      )
      # Notif.push_ios("主催している大会の開始予定時刻になりました。大会を開始してください！", "", "reminder_to_start_tournament", device.token, 6, params)
    end
  end

  def notify_tournament_start(id) do
    tournament = Tournaments.get_tournament(id)
  #IO.inspect(tournament)
    if tournament do
      devices =
        for entrant <- Map.get(tournament, :entrant) do
            Accounts.get_devices_by_user_id(entrant.user_id)
        end
        |> List.flatten()

      for device <- devices do
        if device.user_id != tournament.master_id do
          params = %{tournament_id: id}
          Notif.push_ios(
            device.user_id,
            device.token,
            7,
            tournament.name,
            "大会が始まりました",
            params
          )
        end
        # Notif.push_ios("大会が始まりました！", "", "tournament_start", device.token, 6, params)
      end
    else
      IO.puts("tournament not found")
    end
  end
end

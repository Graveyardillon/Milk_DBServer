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
    tournament = Tournaments.load_tournament(id)
    devices = Accounts.get_devices_by_user_id(tournament.master_id)

    %{
      "user_id" => tournament.master_id,
      "process_id" => "REMIND_TO_START_TOURNAMENT",
      "icon_path" => tournament.icon_path,
      "title" => tournament.name,
      "body_text" => "主催している大会の開始予定時刻になりました。大会を開始してください！",
      "data" =>
        Jason.encode!(%{
          tournament_id: tournament.id
        })
    }
    |> Notif.create_notification()

    for device <- devices do
      %Maps.PushIos{
        user_id: device.user_id,
        device_token: device.token,
        process_id: "REMIND_TO_START_TOURNAMENT",
        title: tournament.name,
        message: "主催している大会の開始予定時刻になりました。大会を開始してください！",
        params: %{"tournament_id" => id}
      }
      |> Milk.Notif.push_ios()
    end
  end

  def notify_tournament_start(id) do
    tournament = Tournaments.load_tournament(id)

    if tournament do
      devices =
        for entrant <- Map.get(tournament, :entrant) do
          Accounts.get_devices_by_user_id(entrant.user_id)
        end
        |> List.flatten()

      for device <- devices do
        if device.user_id != tournament.master_id do
          # App Notification
          %{
            "user_id" => device.user_id,
            "process_id" => "TOURNAMENT_START",
            "icon_path" => "",
            "title" => "大会が始まりました",
            "body_text" => "#{tournament.name}",
            "data" =>
              Jason.encode!(%{
                tournament_id: tournament.id
              })
          }
          |> Notif.create_notification()

          # Push Notification
          %Maps.PushIos{
            user_id: device.user_id,
            device_token: device.token,
            process_id: "TOURNAMENT_START",
            title: tournament.name,
            message: "大会が始まりました",
            params: %{"tournament_id" => id}
          }
          |> Milk.Notif.push_ios()
        end
      end
    else
      IO.puts("tournament not found")
    end
  end
end

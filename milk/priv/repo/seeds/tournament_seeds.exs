use Timex

alias Milk.Tournaments.Tournament
alias Milk.Accounts.User
alias Milk.Repo

user = Repo.insert! %User{
  bio: "Test user which has many tournaments.",
  icon_path: nil,
  id_for_show: -1,
  name: "Test tournament holder"
}

now = Timex.now()
tomorrow =
  Timex.now()
  |> Timex.add(Timex.Duration.from_days(1))
  |> Timex.to_datetime()

Repo.insert! %Tournament{
  capacity: 4,
  deadline: tomorrow,
  description: "test tournament of size 4.",
  event_date: tomorrow,
  name: "test tournament size 4",
  type: 0,
  url: nil,
  thumbnail_path: nil,
  password: nil,
  game_name: "my awesome name",
  start_recruiting: now,
  start_notification_pid: nil,
  master_id: user.id,
  platform_id: 1,
  game_id: nil
}

Repo.insert! %Tournament{
  capacity: 5,
  deadline: tomorrow,
  description: "test tournament of size 5.",
  event_date: tomorrow,
  name: "test tournament size 5",
  type: 0,
  url: nil,
  thumbnail_path: nil,
  password: nil,
  game_name: "my awesome name",
  start_recruiting: now,
  start_notification_pid: nil,
  master_id: user.id,
  platform_id: 1,
  game_id: nil
}

Repo.insert! %Tournament{
  capacity: 6,
  deadline: tomorrow,
  description: "test tournament of size 6.",
  event_date: tomorrow,
  name: "test tournament size 6",
  type: 0,
  url: nil,
  thumbnail_path: nil,
  password: nil,
  game_name: "my awesome name",
  start_recruiting: now,
  start_notification_pid: nil,
  master_id: user.id,
  platform_id: 1,
  game_id: nil
}

Repo.insert! %Tournament{
  capacity: 7,
  deadline: tomorrow,
  description: "test tournament of size 7.",
  event_date: tomorrow,
  name: "test tournament size 7",
  type: 0,
  url: nil,
  thumbnail_path: nil,
  password: nil,
  game_name: "my awesome name",
  start_recruiting: now,
  start_notification_pid: nil,
  master_id: user.id,
  platform_id: 1,
  game_id: nil
}

Repo.insert! %Tournament{
  capacity: 8,
  deadline: tomorrow,
  description: "test tournament of size 8.",
  event_date: tomorrow,
  name: "test tournament size 8",
  type: 0,
  url: nil,
  thumbnail_path: nil,
  password: nil,
  game_name: "my awesome name",
  start_recruiting: now,
  start_notification_pid: nil,
  master_id: user.id,
  platform_id: 1,
  game_id: nil
}

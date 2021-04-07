use Timex

alias Milk.Repo
alias Milk.Tournaments.Tournament
alias Milk.Accounts.{
  Auth,
  User
}

user = Repo.insert! %User{
  bio: "Test user which has many tournaments.",
  icon_path: nil,
  id_for_show: -1,
  name: "TestTournamentHolder"
}
Repo.insert! %Auth{
  user_id: user.id,
  email: user.name <> "@mail.com",
  password: Argon2.hash_pwd_salt("LookAtMePW")
}

now = Timex.now()
tomorrow =
  Timex.now()
  |> Timex.add(Timex.Duration.from_days(1))
  |> Timex.to_datetime()

File.cp("./priv/repo/seeds/image/2pimp.jpg", "./static/image/tournament_thumbnail/2pimp.jpg")
Repo.insert! %Tournament{
  capacity: 4,
  deadline: tomorrow,
  description: "test tournament of size 4.",
  event_date: tomorrow,
  name: "test tournament size 4",
  type: 1,
  url: nil,
  thumbnail_path: "2pimp",
  password: nil,
  game_name: "my awesome name",
  start_recruiting: now,
  start_notification_pid: nil,
  master_id: user.id,
  platform_id: 1,
  game_id: nil
}

File.cp("./priv/repo/seeds/image/damn.jpg", "./static/image/tournament_thumbnail/damn.jpg")
Repo.insert! %Tournament{
  capacity: 5,
  deadline: tomorrow,
  description: "test tournament of size 5.",
  event_date: tomorrow,
  name: "test tournament size 5",
  type: 1,
  url: nil,
  thumbnail_path: "damn",
  password: nil,
  game_name: "my awesome name",
  start_recruiting: now,
  start_notification_pid: nil,
  master_id: user.id,
  platform_id: 1,
  game_id: nil
}

File.cp("./priv/repo/seeds/image/darksideofthemoon.jpg", "./static/image/tournament_thumbnail/darksideofthemoon.jpg")
Repo.insert! %Tournament{
  capacity: 6,
  deadline: tomorrow,
  description: "test tournament of size 6.",
  event_date: tomorrow,
  name: "test tournament size 6",
  type: 1,
  url: nil,
  thumbnail_path: "darksideofthemoon",
  password: nil,
  game_name: "my awesome name",
  start_recruiting: now,
  start_notification_pid: nil,
  master_id: user.id,
  platform_id: 1,
  game_id: nil
}

File.cp("./priv/repo/seeds/image/kazemachi.jpg", "./static/image/tournament_thumbnail/kazemachi.jpg")
Repo.insert! %Tournament{
  capacity: 7,
  deadline: tomorrow,
  description: "test tournament of size 7.",
  event_date: tomorrow,
  name: "test tournament size 7",
  type: 1,
  url: nil,
  thumbnail_path: "kazemachi",
  password: nil,
  game_name: "my awesome name",
  start_recruiting: now,
  start_notification_pid: nil,
  master_id: user.id,
  platform_id: 1,
  game_id: nil
}

File.cp("./priv/repo/seeds/image/nevermind.jpg", "./static/image/tournament_thumbnail/nevermind.jpg")
Repo.insert! %Tournament{
  capacity: 8,
  deadline: tomorrow,
  description: "test tournament of size 8.",
  event_date: tomorrow,
  name: "test tournament size 8",
  type: 1,
  url: nil,
  thumbnail_path: "nevermind",
  password: nil,
  game_name: "my awesome name",
  start_recruiting: now,
  start_notification_pid: nil,
  master_id: user.id,
  platform_id: 1,
  game_id: nil
}

File.cp("./priv/repo/seeds/image/solid_state_survivor.jpg", "./static/image/tournament_thumbnail/solid_state_survivor.jpg")
Repo.insert! %Tournament{
  capacity: 32,
  deadline: tomorrow,
  description: "test tournament of size 32.",
  event_date: tomorrow,
  name: "test tournament size 32",
  type: 1,
  url: nil,
  thumbnail_path: "solid_state_survivor",
  password: nil,
  game_name: "my awesome name",
  start_recruiting: now,
  start_notification_pid: nil,
  master_id: user.id,
  platform_id: 1,
  game_id: nil
}

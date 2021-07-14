use Timex

alias Milk.{
  Platforms,
  Repo,
  Tournaments
}
alias Milk.Accounts.{
  Auth,
  User
}

file = "free-engineer"
File.cp("./priv/repo/seeds/image/#{file}.jpg", "./static/image/profile_icon/#{file}.jpg")

user = Repo.insert! %User{
  bio: "Test user which has many tournaments.",
  icon_path: "./static/image/profile_icon/#{file}.jpg",
  id_for_show: -1,
  name: "TestTournamentHolder"
}
Repo.insert! %Auth{
  user_id: user.id,
  email: user.name <> "@mail.com",
  password: Argon2.hash_pwd_salt("LookAtMePW")
}

Platforms.create_basic_platforms()

now = Timex.now()
tomorrow = Timex.now()
  |> Timex.add(Timex.Duration.from_days(1))
  |> Timex.to_datetime()
day_after_tomorrow = Timex.now()
  |> Timex.add(Timex.Duration.from_days(2))
  |> Timex.to_datetime()

file = "free-forest"
File.cp("./priv/repo/seeds/image/#{file}.jpg", "./static/image/tournament_thumbnail/#{file}.jpg")
attrs = %{
  "capacity" => 4,
  "deadline" => tomorrow,
  "description" => "test tournament of size 4.",
  "event_date" => tomorrow,
  "name" => "test tournament size 4",
  "type" => 1,
  "url" => nil,
  "thumbnail_path" => file,
  "password" => nil,
  "game_name" => "my awesome name",
  "start_recruiting" => now,
  "master_id" => user.id,
  "platform" => 1,
  "game_id" => nil
}
Tournaments.create_tournament(attrs, attrs["thumbnail_path"])

file = "free-astro"
File.cp("./priv/repo/seeds/image/#{file}.jpg", "./static/image/tournament_thumbnail/#{file}.jpg")
attrs = %{
  "capacity" => 5,
  "deadline" => day_after_tomorrow,
  "description" => "test tournament of size 5.",
  "event_date" => day_after_tomorrow,
  "name" => "test tournament size 5",
  "type" => 1,
  "url" => "test url",
  "thumbnail_path" => file,
  "password" => nil,
  "game_name" => "my awesome name",
  "is_team" => true,
  "team_size" => 5,
  "start_recruiting" => now,
  "master_id" => user.id,
  "platform" => 1,
  "game_id" => nil
}
Tournaments.create_tournament(attrs, attrs["thumbnail_path"])

file = "free-monkey"
File.cp("./priv/repo/seeds/image/#{file}.jpg", "./static/image/tournament_thumbnail/#{file}.jpg")
attrs = %{
  "capacity" => 6,
  "deadline" => tomorrow,
  "description" => "test tournament of size 6.",
  "event_date" => tomorrow,
  "name" => "test tournament size 6",
  "type" => 2,
  "url" => nil,
  "thumbnail_path" => file,
  "password" => nil,
  "game_name" => "my awesome name",
  "start_recruiting" => now,
  "master_id" => user.id,
  "platform" => 1,
  "game_id" => nil
}
Tournaments.create_tournament(attrs, attrs["thumbnail_path"])

file = "free-sunset"
File.cp("./priv/repo/seeds/image/#{file}.jpg", "./static/image/tournament_thumbnail/#{file}.jpg")
attrs = %{
  "capacity" => 7,
  "deadline" => day_after_tomorrow,
  "description" => "test tournament of size 7.",
  "event_date" => day_after_tomorrow,
  "name" => "test tournament size 7",
  "type" => 1,
  "url" => nil,
  "thumbnail_path" => file,
  "password" => "8880",
  "game_name" => "my awesome name",
  "start_recruiting" => now,
  "master_id" => user.id,
  "platform" => 1,
  "game_id" => nil
}
Tournaments.create_tournament(attrs, attrs["thumbnail_path"])

file = "free-wave"
File.cp("./priv/repo/seeds/image/#{file}.jpg", "./static/image/tournament_thumbnail/#{file}.jpg")
attrs = %{
  "capacity" => 8,
  "deadline" => tomorrow,
  "description" => "test tournament of size 8.",
  "event_date" => tomorrow,
  "name" => "test tournament size 8",
  "type" => 1,
  "url" => nil,
  "thumbnail_path" => file,
  "password" => nil,
  "game_name" => "my awesome name",
  "start_recruiting" => now,
  "master_id" => user.id,
  "platform" => 1,
  "game_id" => nil
}
Tournaments.create_tournament(attrs, attrs["thumbnail_path"])

file = "free-engineer"
File.cp("./priv/repo/seeds/image/#{file}.jpg", "./static/image/tournament_thumbnail/#{file}.jpg")
attrs = %{
  "capacity" => 32,
  "deadline" => tomorrow,
  "description" => "test tournament of size 32.",
  "event_date" => tomorrow,
  "name" => "test tournament size 32",
  "type" => 1,
  "url" => nil,
  "thumbnail_path" => file,
  "password" => nil,
  "game_name" => "my awesome name",
  "start_recruiting" => now,
  "master_id" => user.id,
  "platform" => 1,
  "game_id" => nil
}
Tournaments.create_tournament(attrs, attrs["thumbnail_path"])

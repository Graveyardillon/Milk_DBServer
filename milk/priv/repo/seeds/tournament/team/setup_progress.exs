use Timex

import Common.Sperm

alias Milk.{
  Accounts,
  Tournaments
}

team_n = 4
team_size = 5

Timex.now()
~> now
|> Timex.add(Timex.Duration.from_days(2))
|> Timex.to_datetime()
~> day_after_tomorrow

1..team_n*team_size+1
|> Enum.to_list()
|> Enum.map(fn n ->
  %{
    "email" => "test#{n}user@gmail.com",
    "name" => "test#{n}user",
    "password" => "Password123"
  }
  |> Accounts.create_user()
  |> elem(1)
end)
~> [organizer | users]

# 大会作成
organizer
|> (fn user ->
  File.cp("./priv/repo/seeds/image/damn.jpg", "./static/image/tournament_thumbnail/damn.jpg")
  attrs = %{
    "capacity" => 4,
    "deadline" => day_after_tomorrow,
    "description" => "test team tournament of size 4.",
    "enabled_coin_toss" => true,
    "enabled_multiple_selection" => true,
    "event_date" => day_after_tomorrow,
    "name" => "test team tournament of size 4.",
    "type" => 2,
    "url" => "test url",
    "thumbnail_path" => "damn",
    "password" => nil,
    "game_name" => "my awesome name",
    "is_team" => true,
    "team_size" => 5,
    "start_recruiting" => now,
    "master_id" => user.id,
    "platform" => 1,
    "game_id" => nil,
    "coin_head_field" => "マップ選択",
    "coin_tail_field" => "A/D選択",
    "multiple_selection_label" => "マップ",
    "multiple_selections" => [
      %{
        "name" => "アセント",
        "icon_path" => "./static/image/options/ascent.png"
      },
      %{
        "name" => "バインド",
        "icon_path" => "./static/image/options/bind.png"
      },
      %{
        "name" => "ブリーズ",
        "icon_path" => "./static/image/options/breeze.png"
      },
      %{
        "name" => "ヘイヴン",
        "icon_path" => "./static/image/options/haven.png"
      },
      %{
        "name" => "アイスボックス",
        "icon_path" => "./static/image/options/icebox.png"
      },
      %{
        "name" => "スプリット",
        "icon_path" => "./static/image/options/split.png"
      }
    ]
  }
  Tournaments.create_tournament(attrs, attrs["thumbnail_path"])
  |> elem(1)
end).()
~> tournament

users
|> Enum.map(fn user ->
  user.id
end)
|> Enum.chunk_every(team_size)
|> Enum.map(fn [leader | members] ->
  tournament.id
  |> Tournaments.create_team(team_size, leader, members)
  |> elem(1)
end)
|> Enum.map(fn team ->
  team.id
  |> Tournaments.get_team_members_by_team_id()
  |> Enum.map(fn member ->
    member.id
    |> Tournaments.create_team_invitation(1)
    |> elem(1)
    |> Map.get(:id)
    |> Tournaments.confirm_team_invitation()
  end)
end)

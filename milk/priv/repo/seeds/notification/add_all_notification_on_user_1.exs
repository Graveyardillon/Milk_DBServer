alias Milk.Notif

[
  %{
    "user_id" => 1,
    "content" => "chore",
    "data" => nil,
    "process_id" => "COMMON"
  },
  %{
    "user_id" => 1,
    "content" => "ビバンダム君",
    "data" => nil,
    "process_id" => "COMMON"
  },
  %{
    "user_id" => 1,
    "content" => "ライブ",
    "data" => nil,
    "process_id" => "COMMON"
  },
  %{
    "user_id" => 1,
    "content" => "ビバンダム君",
    "data" => nil,
    "process_id" => "COMMON"
  },
  %{
    "user_id" => 1,
    "content" => "ビバンダム君",
    "data" => nil,
    "process_id" => "COMMON"
  },
  %{
    "user_id" => 1,
    "content" => "ビバンダム君が大会主催",
    "data" => nil,
    "process_id" => "FOLLOWING_USER_PLANNED_TOURNAMENT",
    "icon_path" => "./static/image/tournament_thumbnail/2pimp.jpg"
  },
  %{
    "user_id" => 1,
    "content" => "ビバンダム君",
    "data" => nil,
    "process_id" => "TOURNAMENT_START",
    "icon_path" => "2pimp"
  },
  %{
    "user_id" => 1,
    "content" => "",
    "data" => nil,
    "process_id" => "DUPLICATE_CLAIM"
  }
]
|> Enum.each(fn notification ->
  Notif.create_notification(notification)
end)

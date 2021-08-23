alias Milk.Notif

[
  %{
    "user_id" => 1,
    "process_id" => "TEAM_INVITE",
    "icon_path" => nil,
    "title" => "User1 からチーム招待されました",
    # "body_text" => "",
    "data" => Jason.encode!(%{invitation_id: 999})
  },
  %{
    "user_id" => 1,
    "title" => "chore",
    "body_text" => "body body body",
    "data" => nil,
    "process_id" => "COMMON"
  },
  %{
    "user_id" => 1,
    "title" => "ビバンダム君",
    "body_text" => "body body body",
    "data" => nil,
    "process_id" => "COMMON"
  },
  %{
    "user_id" => 1,
    "title" => "ライブ",
    "body_text" => "body body body",
    "data" => nil,
    "process_id" => "COMMON"
  },
  %{
    "user_id" => 1,
    "title" => "ビバンダム君",
    "body_text" => "body body body",
    "data" => nil,
    "process_id" => "COMMON"
  },
  %{
    "user_id" => 1,
    "title" => "ビバンダム君",
    "body_text" => "body body body",
    "data" => nil,
    "process_id" => "COMMON"
  },
  %{
    "user_id" => 1,
    "title" => "ビバンダム君が大会主催",
    "body_text" => "body body body",
    "data" => Jason.encode!(%{tournament_id: 1}),
    "process_id" => "FOLLOWING_USER_PLANNED_TOURNAMENT",
    "icon_path" => "./static/image/tournament_thumbnail/2pimp.jpg"
  },
  %{
    "user_id" => 1,
    "title" => "ビバンダム君",
    "body_text" => "body body body",
    "data" => Jason.encode!(%{tournament_id: 1}),
    "process_id" => "TOURNAMENT_START",
    "icon_path" => "2pimp"
  },
  %{
    "user_id" => 1,
    "title" => "重複した勝敗報告が起きています",
    "data" => nil,
    "process_id" => "DUPLICATE_CLAIM"
  }
]
|> Enum.each(fn notification ->
  Notif.create_notification(notification)
end)

alias Milk.Notif

[
  %{
    "user_id" => 1,
    "content" => "chore",
    "data" => nil,
    "process_code" => 0
  },
  %{
    "user_id" => 1,
    "content" => "ビバンダム君",
    "data" => nil,
    "process_code" => 1
  },
  %{
    "user_id" => 1,
    "content" => "ライブ",
    "data" => nil,
    "process_code" => 2
  },
  %{
    "user_id" => 1,
    "content" => "ビバンダム君",
    "data" => nil,
    "process_code" => 3
  },
  %{
    "user_id" => 1,
    "content" => "ビバンダム君",
    "data" => nil,
    "process_code" => 4
  },
  %{
    "user_id" => 1,
    "content" => "ビバンダム君",
    "data" => nil,
    "process_code" => 5
  },
  %{
    "user_id" => 1,
    "content" => "ビバンダム君",
    "data" => nil,
    "process_code" => 6
  },
  %{
    "user_id" => 1,
    "content" => "",
    "data" => nil,
    "process_code" => 7
  }
]
|> Enum.each(fn notification ->
  Notif.create_notification(notification)
end)

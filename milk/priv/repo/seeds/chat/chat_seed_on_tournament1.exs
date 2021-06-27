alias Milk.Chat

1..20
|> Enum.to_list()
|> Enum.map(fn n ->
  %{"user_id" => rem(n, 4)+1, "chat_room_id" => rem(n, 3)+1, "word" => "Hello #{n}!"}
end)
|> Enum.each(fn map ->
  Chat.dialogue(map)
end)

1..20
|> Enum.to_list()
|> Enum.map(fn n ->
  %{"user_id" => rem(n, 4)+1, "chat_room_id" => rem(n, 3)+1, "word" => "Let's break line\n (broken): #{n}"}
end)
|> Enum.each(fn map ->
  Chat.dialogue(map)
end)

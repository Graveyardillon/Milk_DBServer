alias Milk.Relations

2..4
|> Enum.to_list()
|> Enum.each(fn n ->
  %{"follower_id" => 1, "followee_id" => n}
  |> Relations.create_relation()
end)

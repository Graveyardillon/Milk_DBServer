alias Milk.Relations

2..5
|> Enum.each(fn n ->
  Relations.block(1, n)
end)

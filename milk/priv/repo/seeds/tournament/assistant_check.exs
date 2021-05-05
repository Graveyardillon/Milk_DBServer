alias Milk.Tournaments

%{"tournament_id" => 1, "user_id" => [2]}
|> Tournaments.create_assistants()
|> IO.inspect()

# %{"tournament_id" => 1, "user_id" => 3}
# |> Tournaments.create_assistant()
# |> IO.inspect()

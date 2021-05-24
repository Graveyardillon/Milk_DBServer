alias Milk.Accounts

users_num = 20
rep = 100
users = Enum.to_list(1..users_num)
games = ["Fortnite", "Apex Legends", "Clash Royale", "Valorant", "League of Legends",
"Smash Brawl", "Shadowverse", "Rocket League", "Pokemon", "CoD", "CSGO", "DOTA2"]
gains = [1, 5, 7]

users
|> Enum.each(fn n ->
  1..rep
  |> Enum.to_list()
  |> Enum.each(fn _ ->
    %{
      "user_id" => Enum.random(users),
      "game_name" => Enum.random(games),
      "score" => Enum.random(gains)
    }
    |> Accounts.gain_score()
  end)
end)

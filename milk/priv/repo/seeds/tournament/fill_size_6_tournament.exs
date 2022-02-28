#
alias Milk.{
  Accounts,
  Repo,
  Tournaments
}
alias Milk.Accounts.{
  Auth,
  User
}
alias Milk.Tournaments.{
  Entrant,
  Progress,
  Tournament
}

import Ecto.Query, only: [from: 2]

require Logger

tournament = Repo.one(from t in Tournament, where: t.capacity == 6)

1..6
|> Enum.map(fn n ->
  Repo.insert! %User{
    bio: "Test user for filling size 6 tournament.",
    icon_path: nil,
    id_for_show: n,
    name: to_string(n) <> "TestEntrantOfSize4Tournament"
  }
end)
|> Enum.map(fn user ->
  Repo.insert! %Auth{
    user_id: user.id,
    email: user.name <> "@mail.com",
    password: Argon2.hash_pwd_salt("thisisaSECURITYHOLE")
  }
end)
|> Enum.each(fn user ->
  %{
    "tournament_id" => tournament.id,
    "user_id" => user.id
  }
  |> Tournaments.create_entrant()
end)

Tournaments.start(tournament)
{:ok, match_list} =
  Tournaments.get_entrants(tournament.id)
  |> Enum.map(fn x -> x.user_id end)
  |> Tournaments.generate_matchlist()
count =
  Tournaments.load_tournament(tournament.id)
  |> Map.get(:count)
match_list
|> Tournaments.initialize_rank(count, tournament.id)
match_list
|> Progress.insert_match_list(tournament.id)

list_with_fight_result =
  match_list
  |> Tournaments.initialize_match_list_with_fight_result()

lis =
  list_with_fight_result
  |> List.flatten()

Enum.reduce(lis, list_with_fight_result, fn x, acc ->
  user = Accounts.get_user(x["user_id"])

  acc
  |> Tournaments.put_value_on_brackets(user.id, %{"name" => user.name})
  |> Tournaments.put_value_on_brackets(user.id, %{"win_count" => 0})
  |> Tournaments.put_value_on_brackets(user.id, %{"icon_path" => user.icon_path})
end)
|> Progress.insert_match_list_with_fight_result(tournament.id)

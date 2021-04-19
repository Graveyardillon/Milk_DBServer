alias Milk.{
  Accounts,
  Repo,
  TournamentProgress,
  Tournaments
}
alias Milk.Accounts.{
  Auth,
  User
}
alias Milk.Tournaments.{
  Entrant
}

import Ecto.Query, only: [from: 2]

require Logger

tournament = Repo.one(from t in Tournament, where: t.capacity == 4)

1..4
|> Enum.map(fn n ->
  Repo.insert! %User{
    bio: "Test user for filling size 4 tournament.",
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
  Repo.insert! %Entrant{
    tournament_id: tournament.id,
    user_id: user.id
  }
end)

Tournaments.start(tournament.master_id, tournament.id)
{:ok, match_list} =
  Tournaments.get_entrants(tournament.id)
  |> Enum.map(fn x -> x.user_id end)
  |> Tournaments.generate_matchlist()
count =
  Tournaments.get_tournament(tournament.id)
  |> Map.get(:count)
match_list
|> Tournaments.initialize_rank(count, tournament.id)
match_list
|> TournamentProgress.insert_match_list(tournament.id)

list_with_fight_result =
  match_list
  |> Tournaments.initialize_match_list_with_fight_result()

lis =
  list_with_fight_result
  |> Tournamex.match_list_to_list()

Enum.reduce(lis, list_with_fight_result, fn x, acc ->
  user = Accounts.get_user(x["user_id"])

  acc
  |> Tournaments.put_value_on_brackets(user.id, %{"name" => user.name})
  |> Tournaments.put_value_on_brackets(user.id, %{"win_count" => 0})
  |> Tournaments.put_value_on_brackets(user.id, %{"icon_path" => user.icon_path})
end)
|> TournamentProgress.insert_match_list_with_fight_result(tournament.id)

with [{_, match_list}] <- TournamentProgress.get_match_list(tournament.id) do
  IO.inspect(match_list, label: :match_list_in_fill_size_4_tournament)
  Logger.info("Set time limit on all entrants")
  TournamentProgress.set_time_limit_on_all_entrants(match_list, tournament.id)
end

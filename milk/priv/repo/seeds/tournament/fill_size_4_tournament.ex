alias Milk.Accounts.{
  User,
  Auth
}
alias Milk.Tournaments.{
  Entrant,
  Tournament
}
alias Milk.Repo
alias Milk.Tournaments

import Ecto.Query, only: [from: 2]

tournament = Repo.one(from t in Tournament, where: t.capacity == 4)

1..4
|> Enum.map(fn n ->
  Repo.insert! %User{
    bio: "Test user for filling size 4 tournament.",
    icon_path: nil,
    id_for_show: n,
    name: "TestEntrantOfSize4Tournament" <> to_string(n)
  }
end)
|> Enum.map(fn user ->
  Repo.insert! %Auth{
    user_id: user.id,
    email: user.name <> "@mail.com",
    password: "thisisaSECURITYHOLE"
  }
end)
|> Enum.each(fn user ->
  Repo.insert! %Entrant{
    tournament_id: tournament.id,
    user_id: user.id
  }
end)

Tournaments.start(tournament.master_id, tournament.id)

import Common.Sperm
import Ecto.Query, warn: false

alias Milk.Repo
alias Milk.Tournaments.{
  Progress,
  Tournament
}

# XXX: DEPRECATED

Tournament
|> where([t], t.is_team)
|> Repo.one()
~> tournament

Progress.start_team_flipban(tournament)

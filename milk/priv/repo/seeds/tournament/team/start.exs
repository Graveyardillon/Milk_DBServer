import Common.Sperm
import Ecto.Query, warn: false

alias Milk.Repo
alias Milk.Tournaments.{
  Progress,
  Tournament
}

Tournament
|> where([t], t.is_team)
|> Repo.one()
~> tournament

Progress.start_team_best_of_format(tournament.master_id, tournament)

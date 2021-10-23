import Common.Sperm
import Ecto.Query, warn: false

alias Milk.{
  Repo,
  Tournaments.Progress
}
alias Milk.Tournaments.Tournament

Tournament
|> where([t], t.is_team)
|> Repo.one()
~> tournament

Tournaments.Progress.start_team_best_of_format(tournament.master_id, tournament)

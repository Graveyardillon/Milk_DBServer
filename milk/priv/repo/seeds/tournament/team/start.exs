import Common.Sperm
import Ecto.Query, warn: false

alias Milk.{
  Repo,
  TournamentProgress,
  Tournaments
}
alias Milk.Tournaments.Tournament

Tournament
|> where([t], t.is_team)
|> Repo.one()
~> tournament

tournament
|> Map.get(:id)
|> Tournaments.start_team_tournament(tournament.master_id)

TournamentProgress.start_team_best_of_format(tournament.master_id, tournament)

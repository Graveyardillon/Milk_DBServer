defmodule Milk.Profiles do
  import Ecto.Query, warn: false
  import Common.Sperm

  alias Milk.Accounts.{
    User
  }

  alias Milk.Log.{
    EntrantLog,
    TournamentLog
  }

  alias Milk.Repo

  @doc """
  Get added records of the user.
  """
  def get_records(user) do
    EntrantLog
    |> where([el], el.user_id == ^user.id and el.show_on_profile == true)
    |> Repo.all()
    |> Enum.map(fn entrant_log ->
      TournamentLog
      |> where([tl], tl.tournament_id == ^entrant_log.tournament_id)
      |> Repo.one()
      ~> tlog

      Map.put(entrant_log, :tournament_log, tlog)
    end)
    |> Enum.reject(&is_nil(&1.tournament_log))

    # TeamMemberLog
    # |> where([tm], tm.user_id == ^user.id)
    # |> Repo.all()
    # |> Enum.map(fn member ->
    #   TeamLog
    #   |> where([t], t.id == ^member.team_id)
    #   |> Repo.one()
    #   ~> team_log
    #   |> is_nil()
    #   |> unless do
    #     TournamentLog
    #     |> where([tl], tl.tournament_id == ^team_log.tournament_id)
    #     |> Repo.one()
    #     ~> tlog

    #     Map.put(team_log, :tournament_log, tlog)
    #   end
    # end)
    # |> Enum.filter(fn log -> !is_nil(log) end)
    # |> Enum.concat(records)
    # |> Enum.uniq()
  end

  def update_recordlist(%User{} = user, record_list) do
    EntrantLog
    |> where([el], el.user_id == ^user.id)
    |> Repo.all()
    |> Enum.map(fn el_log ->
      show_on_profile = Enum.member?(record_list, to_string(el_log.tournament_id))

      el_log
      |> EntrantLog.changeset(%{show_on_profile: show_on_profile})
      |> Repo.update()
    end)
  end
end

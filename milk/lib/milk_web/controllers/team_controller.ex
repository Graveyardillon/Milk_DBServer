defmodule MilkWeb.TeamController do
  use MilkWeb, :controller

  alias Common.Tools
  alias Milk.Tournaments

  # @doc """
  # Create team.
  # """
  # def create_team(conn, %{"tournament_id" => tournament_id, "size" => size, "leader_id", leader_id, "user_id_list" => user_id_list}) do
  #   tournament_id = Tools.to_integer_as_needed(tournament_id)
  #   size = Tools.to_integer_as_needed(size)
  #   leader_id = Tools.to_integer_as_needed(leader_id)
  #   user_id_list = Enum.map(fn user_id -> Tools.to_integer_as_needed(user_id) end)

  #   Tournaments.create_team(tournament_id, size, leader_id, user_id_list)

  #   render
  # end

  @doc """
  Get confirmed teams of a tournament.
  """
  def get_confirmed_teams(conn, %{"tournament_id" => tournament_id}) do
    teams = tournament_id
      |> Tools.to_integer_as_needed()
      |> Tournaments.get_confirmed_teams()

    render(conn, "teams.json", teams: teams)
  end

  @doc """
  Confirm invitation of team
  """
  def confirm_invitation(conn, %{"invitation_id" => invitation_id}) do
    invitation_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.confirm_team_invitation()
    |> case do
      {:ok, _invitation} ->
        json(conn, %{result: true})
      {:error, error} ->
        render(conn, "error.json", error: error)
    end
  end
end

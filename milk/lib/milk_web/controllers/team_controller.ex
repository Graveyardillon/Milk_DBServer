defmodule MilkWeb.TeamController do
  use MilkWeb, :controller

  import Common.Sperm

  alias Common.Tools
  alias Milk.Tournaments

  def show(conn, %{"team_id" => team_id}) do
    team_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.get_team()
    ~> team
    |> is_nil()
    |> unless do
      render(conn, "show.json", team: team)
    else
      render(conn, "error.json", error: nil)
    end
  end

  @doc """
  Get tournament members.
  """
  def get_teammates(conn, %{"tournament_id" => tournament_id, "user_id" => user_id}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    user_id = Tools.to_integer_as_needed(user_id)

    mates = Tournaments.get_teammates(tournament_id, user_id)

    render(conn, "members.json", members: mates)
  end

  @doc """
  Create team.
  """
  def create(conn, %{
        "tournament_id" => tournament_id,
        "size" => size,
        "leader_id" => leader_id,
        "user_id_list" => user_id_list
      }) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    size = Tools.to_integer_as_needed(size)
    leader_id = Tools.to_integer_as_needed(leader_id)
    user_id_list = Enum.map(user_id_list, fn user_id -> Tools.to_integer_as_needed(user_id) end)

    # 人数確認
    tournament_id
    |> Tournaments.get_confirmed_teams()
    |> length()
    |> (fn len ->
          tournament = Tournaments.get_tournament(tournament_id)
        end).()
    |> if do
      render(conn, "error.json", error: "over tournament size")
    else
      # リーダーが重複して作成されないようにする
      tournament_id
      |> Tournaments.get_teammates(leader_id)
      |> Enum.any?(fn member ->
        member.user_id == leader_id
      end)
      |> if do
        render(conn, "error.json", error: "duplicated request from leader")
      else
        tournament_id
        |> Tournaments.create_team(size, leader_id, user_id_list)
        |> case do
          {:ok, team} -> render(conn, "show.json", team: team)
          {:error, error} -> render(conn, "error.json", error: Tools.create_error_message(error))
        end
      end
    end
  end

  @doc """
  Get confirmed teams of a tournament.
  """
  def get_confirmed_teams(conn, %{"tournament_id" => tournament_id}) do
    tournament_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.get_confirmed_teams()
    ~> teams

    render(conn, "index.json", teams: teams)
  end

  @doc """
  Confirm invitation of team
  """
  def confirm_invitation(conn, %{"invitation_id" => invitation_id}) do
    invitation_id = Tools.to_integer_as_needed(invitation_id)

    # 大会のチーム数が埋まってないか確認
    invitation_id
    |> Tournaments.get_team_by_invitation_id()
    |> Map.get(:tournament_id)
    |> Tournaments.get_tournament()
    ~> tournament
    |> Map.get(:id)
    |> Tournaments.get_confirmed_teams()
    |> length()
    ~> teams_count

    if tournament.capacity > teams_count do
      invitation_id
      |> Tools.to_integer_as_needed()
      |> Tournaments.confirm_team_invitation()
      |> case do
        {:ok, invitation} ->
          invitation
          |> Map.get(:team_id)
          |> Tournaments.get_team()
          ~> team

          json(
            conn,
            %{
              result: true,
              is_confirmed: team.is_confirmed,
              tournament_id: team.tournament_id
            }
          )

        {:error, error} ->
          render(conn, "error.json", error: error)
      end
    else
      render(conn, "error.json", error: "full of teams")
    end
  end

  @doc """
  Delete a team
  """
  def delete(conn, %{"team_id" => team_id}) do
    team_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.delete_team()
    |> case do
      {:ok, team} ->
        team
        render(conn, "show.json", team: team)

      {:error, error} ->
        render(conn, "error.json", error: error)
    end
  end
end

defmodule MilkWeb.TeamController do
  use MilkWeb, :controller

  import Common.Sperm

  alias Common.Tools
  alias Milk.{
    Accounts,
    Discord,
    Tournaments
  }

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
          tournament.capacity <= len
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
        associated? = Discord.associated?(leader_id)
        tournament = Tournaments.get_tournament(tournament_id)

        if !is_nil(tournament.discord_server_id) && !associated? do
          render(conn, "error.json", error: "user is not associated with discord")
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

    with %Tournaments.Team{} = team <- Tournaments.get_team_by_invitation_id(invitation_id) do
      with %Tournaments.Tournament{} = tournament <-
             Tournaments.get_tournament(team.tournament_id) do

        tournament.id
        |> Tournaments.get_confirmed_teams()
        |> length()
        ~> confirmed_team_count

        if tournament.capacity > confirmed_team_count do
          # チーム承認の前にdiscordのvalidationを入れる
          invitation_id
          |> Tournaments.get_team_invitation()
          |> Map.get(:team_member)
          |> Map.get(:user_id)
          |> Accounts.get_user()
          |> Map.get(:id)
          |> Discord.associated?()
          ~> associated?

          if !is_nil(tournament.discord_server_id) && !associated? do
            render(conn, "error.json", error: "user is not associated with discord")
          else
            invitation_id
            |> Tournaments.confirm_team_invitation()
            |> case do
              {:ok, invitation} ->
                invitation
                |> Map.get(:team_id)
                |> Tournaments.get_team()
                ~> team

                json(conn, %{
                  result: true,
                  is_confirmed: team.is_confirmed,
                  tournament_id: team.tournament_id
                })

              {:error, error} ->
                render(conn, "error.json", error: error)
            end
          end
        end
      else
        nil -> render(conn, "error.json", error: "tournament not found")
      end
    else
      nil -> render(conn, "error.json", error: "team not found")
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

  def decline_invitation(conn, %{"invitation_id" => id}) do
    case Tournaments.team_invitation_decline(id) do
      {:ok, %Tournaments.TeamInvitation{} = invitation} ->
        json(conn, %{result: true})

      {:error, error} ->
        json(conn, %{result: false})
    end
  end
end

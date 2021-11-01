defmodule MilkWeb.TeamController do
  use MilkWeb, :controller

  import Common.Sperm

  alias Common.Tools

  alias Milk.{
    Accounts,
    Discord,
    Tournaments
  }

  alias Milk.Tournaments.{
    Team,
    TeamInvitation,
    Tournament
  }

  def show(conn, %{"team_id" => team_id}) do
    team_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.get_team()
    ~> team

    do_show(conn, team)
  end

  defp do_show(conn, nil), do: render(conn, "error.json", error: nil)
  defp do_show(conn, %Team{} = team), do: render(conn, "show.json", team: team)

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
    user_id_list = Enum.map(user_id_list, &Tools.to_integer_as_needed(&1))

    # NOTE:Elixir.Argon2.Base 人数確認
    tournament_id
    |> Tournaments.get_confirmed_teams()
    |> length()
    ~> team_count

    render_if_invalid_size(conn, team_count, tournament_id, size, leader_id, user_id_list)
  end

  defp render_if_invalid_size(conn, team_count, tournament_id, size, leader_id, user_id_list) do
    tournament = Tournaments.get_tournament(tournament_id)

    if tournament.capacity <= team_count do
      render(conn, "error.json", error: "over tournament size")
    else
      render_if_duplicated_request(conn, tournament, size, leader_id, user_id_list)
    end
  end

  defp render_if_duplicated_request(conn, tournament, size, leader_id, user_id_list) do
    tournament.id
    |> Tournaments.get_teammates(leader_id)
    |> Enum.any?(&(&1.user_id == leader_id))
    |> if do
      render(conn, "error.json", error: "duplicated request from leader")
    else
      render_if_not_associated_with_discord(conn, tournament, size, leader_id, user_id_list)
    end
  end

  defp render_if_not_associated_with_discord(conn, tournament, size, leader_id, user_id_list) do
    if !is_nil(tournament.discord_server_id) && !Discord.associated?(leader_id) do
      render(conn, "error.json", error: "user is not associated with discord")
    else
      tournament.id
      |> Tournaments.create_team(size, leader_id, user_id_list)
      |> case do
        {:ok, team} -> render(conn, "show.json", team: team)
        {:error, error} -> render(conn, "error.json", error: Tools.create_error_message(error))
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

    with team when not is_nil(team) <- Tournaments.get_team_by_invitation_id(invitation_id),
         tournament when not is_nil(tournament) <- Tournaments.get_tournament(team.tournament_id),
         {:ok, nil} <- validate_team_count(tournament),
         {:ok, nil} <- validate_discord_association_of_user(tournament, invitation_id),
         {:ok, invitation} <- Tournaments.confirm_team_invitation(invitation_id) do
      team = Tournaments.get_team(invitation.team_id)
      Task.async(fn -> send_add_team_discord_notification(team) end)

      json(conn, %{result: true, is_confirmed: team.is_confirmed, tournament_id: team.tournament_id})
    else
      nil -> render(conn, "error.json", error: "team is or tournament nil")
      {:error, message} when is_binary(message) -> render(conn, "error.json", error: message)
      {:error, error} -> render(conn, "error.json", error: Tools.create_error_message(error))
    end
  end

  defp validate_team_count(%Tournament{capacity: capacity, id: id}) do
    id
    |> Tournaments.get_confirmed_teams()
    |> length()
    ~> confirmed_team_count

    if confirmed_team_count >= capacity do
      {:error, "invalid size"}
    else
      {:ok, nil}
    end
  end

  defp validate_discord_association_of_user(%Tournament{discord_server_id: discord_server_id}, _) when is_nil(discord_server_id), do: {:ok, nil}
  defp validate_discord_association_of_user(%Tournament{}, invitation_id) do
    invitation_id
    |> Tournaments.get_team_invitation()
    |> Map.get(:team_member)
    |> Map.get(:user_id)
    |> Accounts.get_user()
    |> Map.get(:id)
    |> Discord.associated?()
    ~> associated?

    if associated? do
      {:ok, nil}
    else
      {:error, "user is not associated with discord"}
    end
  end

  @spec send_add_team_discord_notification(Team.t()) :: any()
  defp send_add_team_discord_notification(team) do
    team
    |> Map.get(:id)
    |> Tournaments.get_team()
    ~> team
    |> Map.get(:is_confirmed)
    |> if do
      team
      |> Map.get(:tournament_id)
      |> Tournaments.get_tournament()
      |> Map.get(:discord_server_id)
      ~> discord_server_id
      |> is_nil()
      |> unless do
        Discord.send_tournament_add_team_notification(discord_server_id, team.name)
      end
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
      {:ok, team} -> render(conn, "show.json", team: team)
      {:error, error} -> render(conn, "error.json", error: error)
    end
  end

  @doc """
  Decline an invitation.
  """
  def decline_invitation(conn, %{"invitation_id" => invitation_id}) do
    invitation_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.team_invitation_decline()
    |> case do
      {:ok, %TeamInvitation{} = _} -> json(conn, %{result: true})
      {:error, _} -> json(conn, %{result: false})
    end
  end

  @doc """
  Add members to a team.
  """
  def add_members(conn, %{"team_id" => team_id, "user_id_list" => user_id_list}) do
    team = Tournaments.get_team(team_id)
    add_members_if_team_exists(conn, team, user_id_list)
  end

  defp add_members_if_team_exists(conn, nil, _),
    do: render(conn, "error.json", error: "attr is nil")

  defp add_members_if_team_exists(conn, team, user_id_list) do
    leader = Enum.find(team.team_member, &(&1.is_leader == true))
    total_count = length(team.team_member) + length(user_id_list)

    if total_count <= team.size do
      team.id
      |> Tournaments.create_team_members(user_id_list)
      |> elem(1)
      |> Enum.each(&Tournaments.create_team_invitation(&1.id, leader.user_id))

      json(conn, %{result: true})
    else
      render(conn, "error.json", error: "invalid size")
    end
  end
end

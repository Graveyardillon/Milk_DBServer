defmodule MilkWeb.TeamController do
  use MilkWeb, :controller

  import Common.Sperm

  alias Common.Tools

  alias Milk.{
    Accounts,
    Discord,
    Log,
    Tournaments
  }

  alias Milk.Log.TeamLog

  alias Milk.Tournaments.{
    Team,
    TeamInvitation,
    Tournament
  }

  def show(conn, %{"team_id" => team_id}) do
    team_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.load_team()
    |> load_team_log_as_needed(team_id)
    ~> team

    do_show(conn, team)
  end

  def show(conn, %{"tournament_id" => tournament_id, "user_id" => user_id}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    user_id = Tools.to_integer_as_needed(user_id)

    team = Tournaments.load_team_by_tournament_id_and_user_id(tournament_id, user_id)

    do_show(conn, team)
  end

  # NOTE: idをteam_idで置き換えてしまう
  defp load_team_log_as_needed(nil, team_id) do
    log = Log.get_team_log_by_team_id(team_id)
    Map.put(log, :id, log.team_id)
  end
  defp load_team_log_as_needed(team, _), do: team

  defp do_show(conn, nil),               do: render(conn, "error.json", error: nil)
  defp do_show(conn, %Team{} = team),    do: render(conn, "show.json", team: team)
  defp do_show(conn, %TeamLog{} = team), do: render(conn, "show.json", team: team)

  @doc """
  Get all teams of a tournament.
  """
  def get_teams(conn, %{"tournament_id" => tournament_id}) do
    tournament_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.load_teams_by_tournament_id()
    ~> teams

    render(conn, "index.json", teams: teams)
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
  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(conn, %{"tournament_id" => tournament_id, "size" => size, "leader_id" => leader_id, "user_id_list" => user_id_list, "name" => name}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    size          = Tools.to_integer_as_needed(size)
    leader_id     = Tools.to_integer_as_needed(leader_id)
    user_id_list  = Enum.map(user_id_list, &Tools.to_integer_as_needed(&1))

    confirmed_teams = Tournaments.get_confirmed_teams(tournament_id)

    with tournament when not is_nil(tournament) <- Tournaments.get_tournament(tournament_id),
         {:ok, nil}                             <- validate_capacity(tournament, confirmed_teams),
         {:ok, nil}                             <- validate_duplicated_request(tournament.id, leader_id),
         {:ok, nil}                             <- validate_associated_with_discord(tournament, leader_id),
         {:ok, team}                            <- Tournaments.create_team(tournament.id, size, leader_id, user_id_list, name) do
      render(conn, "show.json", team: team)
    else
      {:ok, :leader_only, team} ->
        Task.async(fn -> send_add_team_discord_notification(team) end)
        render(conn, "show.json", team: team)
      nil             -> render(conn, "error.json", error: "tournament is nil")
      {:error, error} -> render(conn, "error.json", error: error)
    end
  end

  def create(conn, %{"tournament_id" => tournament_id, "size" => size, "leader_id" => leader_id, "user_id_list" => user_id_list}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    size          = Tools.to_integer_as_needed(size)
    leader_id     = Tools.to_integer_as_needed(leader_id)
    user_id_list  = Enum.map(user_id_list, &Tools.to_integer_as_needed(&1))

    confirmed_teams = Tournaments.get_confirmed_teams(tournament_id)

    with tournament when not is_nil(tournament) <- Tournaments.get_tournament(tournament_id),
         {:ok, nil}                             <- validate_capacity(tournament, confirmed_teams),
         {:ok, nil}                             <- validate_duplicated_request(tournament.id, leader_id),
         {:ok, nil}                             <- validate_associated_with_discord(tournament, leader_id),
         {:ok, team}                            <- Tournaments.create_team(tournament.id, size, leader_id, user_id_list) do
      render(conn, "show.json", team: team)
    else
      {:ok, :leader_only, team} ->
        Task.async(fn -> send_add_team_discord_notification(team) end)
        render(conn, "show.json", team: team)
      nil             -> render(conn, "error.json", error: "tournament is nil")
      {:error, error} -> render(conn, "error.json", error: error)
    end
  end

  defp validate_capacity(nil, _), do: {:error, "tournament is nil"}
  defp validate_capacity(%Tournament{capacity: capacity}, teams) when capacity > length(teams), do: {:ok, nil}
  defp validate_capacity(%Tournament{capacity: capacity}, teams) when capacity <= length(teams), do: {:error, "over tournament size"}
  defp validate_capacity(_, _), do: {:error, "unexpected error on creating tournament"}

  defp validate_duplicated_request(tournament_id, leader_id) do
    tournament_id
    |> Tournaments.get_teammates(leader_id)
    |> Enum.any?(&(&1.user_id == leader_id))
    |> if do
      {:error, "duplicated request from leader"}
    else
      {:ok, nil}
    end
  end

  defp validate_associated_with_discord(%Tournament{discord_server_id: nil}, _), do: {:ok, nil}
  defp validate_associated_with_discord(_, leader_id) do
    if Discord.associated?(leader_id) do
      {:ok, nil}
    else
      {:error, "user is not associated with discord"}
    end
  end

  @doc """
  Get confirmed teams of a tournament.
  """
  def get_confirmed_teams(conn, %{"tournament_id" => tournament_id}) do
    tournament_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.load_confirmed_teams()
    ~> teams

    render(conn, "index.json", teams: teams)
  end

  def get_confirmed_teams_without_members(conn, %{"tournament_id" => tournament_id}) do
    tournament_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.get_confirmed_teams()
    ~> teams

    render(conn, "teams.json", teams: teams)
  end

  @doc """
  Confirm invitation of team
  """
  def confirm_invitation(conn, %{"invitation_id" => invitation_id}) do
    invitation_id = Tools.to_integer_as_needed(invitation_id)

    with team when not is_nil(team)             <- Tournaments.get_team_by_invitation_id(invitation_id),
         tournament when not is_nil(tournament) <- Tournaments.load_tournament(team.tournament_id),
         {:ok, nil}                             <- validate_team_count(tournament),
         {:ok, nil}                             <- validate_discord_association_of_user(tournament, invitation_id),
         {:ok, team_member}                     <- Tournaments.confirm_team_invitation(invitation_id) do
      team = Tournaments.get_team(team_member.team_id)
      Task.async(fn -> send_add_team_discord_notification(team) end)

      json(conn, %{result: true, is_confirmed: team.is_confirmed, tournament_id: team.tournament_id})
    else
      {:error, "short of confirmed" <> _, team_member} ->
        team = Tournaments.get_team(team_member.team_id)
        json(conn, %{result: true, is_confirmed: team.is_confirmed, tournament_id: team.tournament_id})
      nil                                       -> render(conn, "error.json", error: "team or tournament nil")
      {:error, message} when is_binary(message) -> render(conn, "error.json", error: message)
      {:error, error}                           -> render(conn, "error.json", error: Tools.create_error_message(error))
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

  defp validate_discord_association_of_user(%Tournament{discord_server_id: nil}, _), do: {:ok, nil}
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
  defp send_add_team_discord_notification(%Team{is_confirmed: true, name: name, tournament_id: tournament_id}) do
    tournament_id
    |> Tournaments.get_tournament()
    |> Map.get(:discord_server_id)
    ~> discord_server_id
    |> is_nil()
    |> unless do
      Discord.send_tournament_add_team_notification(discord_server_id, name)
    end
  end
  defp send_add_team_discord_notification(_), do: {:ok, nil}

  @doc """
  Delete a team
  """
  def delete(conn, %{"team_id" => team_id}) do
    team_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.delete_team()
    |> case do
      {:ok, team} ->
        Task.async(fn -> send_remove_team_discord_notification(team) end)
        render(conn, "show.json", team: team)
      {:error, error} -> render(conn, "error.json", error: error)
    end
  end

  defp send_remove_team_discord_notification(%Team{is_confirmed: true, name: name, tournament_id: tournament_id}) do
    tournament_id
    |> Tournaments.get_tournament()
    |> Map.get(:discord_server_id)
    ~> discord_server_id
    |> is_nil()
    |> unless do
      Discord.send_tournament_remove_team_notification(discord_server_id, name)
    end
  end
  defp send_remove_team_discord_notification(_), do: {:ok, nil}

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
    team = Tournaments.load_team(team_id)
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

  @doc """
  Resend Team Invitations
  TODO: テスト書いてない
  """
  def resend_team_invitations(conn, %{"team_id" => team_id}) do
    team_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.resend_team_invitations()
    |> case do
      {:ok, _} -> json(conn, %{result: true})
      #_        -> json(conn, %{result: false})
    end
  end
end

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
    TeamInvitation
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
    invitation_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.get_team_by_invitation_id()
    ~> team

    confirm_if_team_exists(conn, team, invitation_id)
  end

  defp confirm_if_team_exists(conn, nil, _), do: render(conn, "error.json", error: "team not found")
  defp confirm_if_team_exists(conn, team, invitation_id) do
    tournament = Tournaments.get_tournament(team.tournament_id)
    confirm_if_tournament_exists(conn, tournament, invitation_id)
  end

  defp confirm_if_tournament_exists(conn, nil, _), do: render(conn, "error.json", error: "tournament not found")
  defp confirm_if_tournament_exists(conn, tournament, invitation_id) do
    tournament.id
    |> Tournaments.get_confirmed_teams()
    |> length()
    ~> confirmed_team_count

    confirm_if_valid_size(conn, confirmed_team_count, tournament, invitation_id)
  end

  defp confirm_if_valid_size(conn, team_count, tournament, invitation_id) do
    if tournament.capacity > team_count do
      confirm_if_associated_with_discord(conn, tournament, invitation_id)
    else
      render(conn, "error.json", error: "invalid size")
    end
  end

  defp confirm_if_associated_with_discord(conn, tournament, invitation_id) do
    # NOTE: チーム承認の前にdiscordのvalidationを入れる
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
      do_confirm(conn, invitation_id)
    end
  end

  defp do_confirm(conn, invitation_id) do
    invitation_id
    |> Tournaments.confirm_team_invitation()
    |> case do
      {:ok, invitation} ->
        invitation.team_id
        |> Tournaments.get_team()
        ~> team
        |> send_add_team_discord_notification()

        json(conn, %{
          result: true,
          is_confirmed: team.is_confirmed,
          tournament_id: team.tournament_id
        })

      {:error, error} -> render(conn, "error.json", error: error)
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

  def add_members(conn, %{"team_id" => team_id, "user_id_list" => user_id_list}) do
    team_id
    |> Tournaments.get_team()
    ~> team
    |> is_nil()
    |> unless do
      leader = Enum.find(team.team_member, fn x -> x.is_leader == true end)
      total = length(team.team_member) + length(user_id_list)

      cond do
        total <= team.size ->
          Tournaments.create_team_members(team_id, user_id_list)
          |> Enum.each(fn member ->
            Tournaments.create_team_invitation(member.id, leader.user_id)
          end)

          json(conn, %{result: true})

        total > team.size ->
          render(conn, "error.json", error: "invalid size")
      end
    else
      render(conn, "error.json", error: nil)
    end
  end
end

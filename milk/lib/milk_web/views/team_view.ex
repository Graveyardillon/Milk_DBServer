defmodule MilkWeb.TeamView do
  use MilkWeb, :view

  alias MilkWeb.{
    TeamView,
    UserView
  }

  def render("index.json", %{teams: teams}) do
    %{
      data: render_many(teams, TeamView, "team.json"),
      result: true
    }
  end

  def render("show.json", %{team: team}) do
    %{
      data: render_one(team, TeamView, "team.json"),
      result: true
    }
  end

  def render("team.json", %{team: team}) do
    %{
      id: team.id,
      is_confirmed: team.is_confirmed,
      name: team.name,
      size: team.size,
      tournament_id: team.tournament_id,
      team_member: render_many(team.team_member, TeamView, "member.json", as: :member)
    }
  end

  def render("member.json", %{member: member}) do
    %{
      id: member.id,
      user: render_one(member.user, UserView, "user.json", as: :user),
      team_id: member.team_id,
      is_leader: member.is_leader,
      is_invitation_confirmed: member.is_invitation_confirmed
    }
  end

  #TODO Remove
  def render("teams.json", %{teams: teams}) do
    %{
      result: true,
      data: Enum.map(teams, fn team ->
        %{
          id: team.id,
          is_confirmed: team.is_confirmed,
          name: team.name,
          tournament_id: team.tournament_id
        }
      end)
    }
  end

  # NOTE: フロント側で型を固定してある
  def render("members.json", %{members: members}) do
    %{
      data:
        Enum.map(members, fn member ->
          %{
            id: member.id,
            user_id: member.user_id,
            user: %{
              bio: member.user.bio,
              email: member.user.auth.email,
              icon_path: member.user.icon_path,
              id: member.user.id,
              name: member.user.name
            },
            team_id: member.team_id,
            is_leader: member.is_leader,
            is_invitation_confirmed: member.is_invitation_confirmed
          }
        end),
      result: true
    }
  end

  def render("error.json", %{error: error}) do
    if error do
      %{result: false, error: error, data: nil}
    else
      %{result: false, error: nil, data: nil}
    end
  end
end

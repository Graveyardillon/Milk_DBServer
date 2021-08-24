defmodule MilkWeb.TournamentView do
  use MilkWeb, :view

  alias MilkWeb.{
    TeamView,
    TournamentView,
    UserView
  }

  def render("users.json", %{users: users}) do
    %{
      data: render_many(users, UserView, "user.json"),
      result: true
    }
  end

  def render("opponent.json", %{opponent: opponent}) do
    %{
      opponent: %{
        id: opponent["id"],
        name: opponent["name"],
        icon_path: opponent["icon_path"],
        point: opponent["point"],
        notification_number: opponent["notification_number"],
        language: opponent["language"],
        email: opponent["auth"]["email"],
        bio: opponent["bio"]
      },
      result: !is_nil(opponent)
    }
  end

  def render("opponent_team.json", %{opponent: opponent, leader: leader}) do
    %{
      opponent: %{
        id: opponent["id"],
        name: leader["name"],
        icon_path: leader["icon_path"],
        rank: opponent["rank"]
      },
      result: !is_nil(opponent) && !is_nil(leader)
    }
  end

  def render("index.json", %{tournament: tournament}) do
    %{
      data: render_many(tournament, TournamentView, "tournament.json"),
      result: true
    }
  end

  def render("show.json", %{tournament: tournament}) do
    %{
      data:
        render_one(tournament, TournamentView, "tournament.json", msg: "Tournament was created!")
    }
  end

  def render("entrants.json", %{entrants: entrants}) do
    %{
      data:
        Enum.map(entrants, fn entrant ->
          %{
            id: entrant.id,
            rank: entrant.rank,
            tournament_id: entrant.tournament_id,
            user_id: entrant.user_id
          }
        end)
    }
  end

  def render("tournament_result.json", %{tournament: tournament}) do
    if tournament == nil do
      %{result: false}
    else
      %{
        result: true,
        data: render_one(tournament, TournamentView, "tournament.json")
      }
    end
  end

  def render("tournament.json", %{tournament: tournament}) do
    %{
      id: tournament.id,
      name: tournament.name,
      thumbnail_path: tournament.thumbnail_path,
      game_id: tournament.game_id,
      game_name: tournament.game_name,
      enabled_coin_toss: tournament.enabled_coin_toss,
      event_date: tournament.event_date,
      start_recruiting: tournament.start_recruiting,
      deadline: tournament.deadline,
      type: tournament.type,
      platform: tournament.platform_id,
      capacity: tournament.capacity,
      has_password: !is_nil(tournament.password),
      description: tournament.description,
      master_id: tournament.master_id,
      url: tournament.url,
      create_time: tournament.create_time,
      update_time: tournament.update_time,
      is_started: tournament.is_started,
      is_team: tournament.is_team,
      team_size: tournament.team_size
    }
  end

  def render("tournament_info.json", %{tournament: tournament}) do
    %{
      data: %{
        id: tournament.id,
        name: tournament.name,
        thumbnail_path: tournament.thumbnail_path,
        game_id: tournament.game_id,
        game_name: tournament.game_name,
        custom_detail:
          unless is_nil(tournament.custom_detail) do
            %{
              coin_head_field: tournament.custom_detail.coin_head_field,
              coin_tail_field: tournament.custom_detail.coin_tail_field,
              multiple_selection_type: tournament.custom_detail.multiple_selection_type
            }
          end,
        event_date: tournament.event_date,
        enabled_coin_toss: tournament.enabled_coin_toss,
        start_recruiting: tournament.start_recruiting,
        deadline: tournament.deadline,
        type: tournament.type,
        platform: tournament.platform_id,
        capacity: tournament.capacity,
        # password: tournament.password,
        has_password: !is_nil(tournament.password),
        description: tournament.description,
        master_id: tournament.master_id,
        url: tournament.url,
        create_time: tournament.create_time,
        update_time: tournament.update_time,
        is_started: tournament.is_started,
        is_team: tournament.is_team,
        team_size: tournament.team_size,
        entrants:
          Enum.map(tournament.entrant, fn entrant ->
            %{
              id: entrant.user.id,
              name: entrant.user.name,
              icon_path: entrant.user.icon_path,
              point: entrant.user.point,
              notification_number: entrant.user.notification_number,
              language: entrant.user.language,
              email: entrant.user.auth.email,
              bio: entrant.user.bio
            }
          end),
        teams:
          Enum.map(tournament.team, fn team ->
            %{
              id: team.id,
              name: team.name,
              size: team.size,
              icon_path: team.icon_path,
              is_confirmed: team.is_confirmed
            }
          end)
      },
      is_log: false,
      result: true
    }
  end

  def render("tournament_include_log.json", %{
        tournaments: tournaments,
        tournament_log: tournament_log
      }) do
    %{
      tournaments:
        render_many(tournaments, TournamentView, "tournament_info_include_entrants.json",
          as: :tournament_info
        ),
      tournament_logs:
        render_many(tournament_log, TournamentView, "tournament_log.json", as: :tournament_log)
    }
  end

  def render("tournament_log.json", %{tournament_log: tournament_log}) do
    %{
      data: %{
        capacity: tournament_log.capacity,
        deadline: tournament_log.deadline,
        description: tournament_log.description,
        event_date: tournament_log.event_date,
        game_id: tournament_log.game_id,
        game_name: tournament_log.game_name,
        tournament_id: tournament_log.tournament_id,
        winner_id: tournament_log.winner_id,
        master_id: tournament_log.master_id,
        name: tournament_log.name,
        url: tournament_log.url,
        type: tournament_log.type,
        thumbnail_path: tournament_log.thumbnail_path,
        entrants:
          Enum.map(tournament_log.entrants, fn user ->
            %{
              user_id: user.user_id
            }
          end)
      },
      is_log: true,
      result: true
    }
  end

  def render("tournament_members.json", %{
        master: master,
        assistants: assistants,
        entrants: entrants,
        teams: teams
      }) do
    %{
      data: %{
        master: render_one(master, UserView, "show.json"),
        assistants: render_many(assistants, UserView, "user.json"),
        entrants: render_many(entrants, UserView, "user.json"),
        teams: render_many(teams, TeamView, "team.json")
      },
      result: true
    }
  end

  def render("home.json", %{tournaments_info: tournaments_info}) do
    inspect(tournaments_info)

    %{
      data:
        render_many(tournaments_info, TournamentView, "tournament_info_include_entrants.json",
          as: :tournament_info
        ),
      result: true
    }
  end

  def render("tournament_info_include_entrants.json", %{tournament_info: tournament}) do
    inspect(tournament)

    %{
      id: tournament.id,
      name: tournament.name,
      thumbnail_path: tournament.thumbnail_path,
      game_id: tournament.game_id,
      game_name: tournament.game_name,
      event_date: tournament.event_date,
      start_recruiting: tournament.start_recruiting,
      deadline: tournament.deadline,
      type: tournament.type,
      platform: tournament.platform_id,
      capacity: tournament.capacity,
      # password: tournament.password,
      has_password: !is_nil(tournament.password),
      description: tournament.description,
      master_id: tournament.master_id,
      url: tournament.url,
      create_time: tournament.create_time,
      update_time: tournament.update_time,
      is_started: tournament.is_started,
      is_team: tournament.is_team,
      entrants:
        Enum.map(tournament.entrants, fn user ->
          %{
            id: user.id,
            name: user.name,
            icon_path: user.icon_path,
            point: user.point,
            notification_number: user.notification_number,
            language: user.language,
            email: user.auth.email,
            bio: user.bio
          }
        end),
      teams:
        if Map.has_key?(tournament, :teams) do
          Enum.map(tournament.teams, fn team ->
            %{
              id: team.id,
              name: team.name,
              size: team.size,
              icon_path: team.icon_path,
              is_confirmed: team.is_confirmed,
              rank: team.rank,
              tournament_id: team.tournament_id
            }
          end)
        else
          nil
        end
    }
  end

  def render("create.json", %{tournament: tournament}) do
    %{
      data: %{
        id: tournament.id,
        name: tournament.name,
        thumbnail_path: tournament.thumbnail_path,
        game_id: tournament.game_id,
        game_name: tournament.game_name,
        enabled_coin_toss: tournament.enabled_coin_toss,
        event_date: tournament.event_date,
        start_recruiting: tournament.start_recruiting,
        deadline: tournament.deadline,
        type: tournament.type,
        platform: tournament.platform_id,
        capacity: tournament.capacity,
        password: tournament.password,
        description: tournament.description,
        master_id: tournament.master_id,
        is_team: tournament.is_team,
        url: tournament.url,
        create_time: tournament.create_time,
        update_time: tournament.update_time,
        followers:
          Enum.map(tournament.followers, fn follower ->
            %{
              id: follower.id,
              name: follower.name
            }
          end)
      },
      result: true
    }
  end

  def render("match.json", %{match_list: list, match_list_with_fight_result: list2}) do
    %{
      result: true,
      data: %{
        match_list: list,
        match_list_with_fight_result: list2
      }
    }
  end

  def render("loser.json", %{list: list}) do
    %{updated_match_list: list}
  end

  def render("tournament_topics.json", %{topics: topics}) do
    map =
      Enum.map(topics, fn topic ->
        %{
          id: topic.id,
          chat_room_id: topic.chat_room_id,
          topic_name: topic.topic_name,
          tournament_id: topic.tournament_id,
          authority: topic.authority,
          can_speak: topic.can_speak
        }
      end)

    %{result: true, data: map}
  end

  # FIXME: Authは読み込んでないのでemailを返すようにしていない
  def render("masters.json", %{masters: masters}) do
    %{
      data:
        Enum.map(masters, fn master ->
          %{
            id: master.id,
            name: master.name,
            icon_path: master.icon_path,
            point: master.point,
            language: master.language,
            bio: master.bio
          }
        end)
    }
  end

  def render("teams.json", %{teams: teams}) do
    %{
      data:
        Enum.map(teams, fn team ->
          %{
            id: team.id,
            name: team.name,
            size: team.size,
            tournament_id: team.tournament_id,
            team_member:
              Enum.map(team.team_member, fn member ->
                %{
                  user_id: member.user_id,
                  team_id: member.team_id,
                  is_leader: member.is_leader,
                  is_invitation_confirmed: member.is_invitation_confirmed
                }
              end)
          }
        end),
      result: true
    }
  end

  def render("match_info.json", %{
        opponent: opponent,
        rank: rank,
        is_team: is_team,
        is_leader: is_leader,
        score: score,
        state: state,
        is_coin_head: is_coin_head,
        custom_detail: custom_detail
      }) do
    %{
      opponent:
        cond do
          is_binary(opponent) ->
            nil

          is_nil(opponent) ->
            nil

          state == "IsAlone" ->
            nil

          is_team ->
            %{
              name: opponent["name"],
              icon_path: opponent["icon_path"],
              id: opponent["id"]
            }

          true ->
            %{
              name: opponent["name"],
              icon_path: opponent["icon_path"],
              id: opponent["id"]
            }
        end,
      rank: rank,
      result: true,
      is_leader:
        if is_team do
          is_leader
        end,
      score: score,
      state: state,
      is_team: is_team,
      is_coin_head: is_coin_head,
      custom_detail:
        if custom_detail do
          %{
            coin_head_field: custom_detail.coin_head_field,
            coin_tail_field: custom_detail.coin_tail_field,
            multiple_selection_type: custom_detail.multiple_selection_type
          }
        end
    }
  end

  def render("error.json", %{error: error}) do
    %{result: false, error: error, data: nil}
  end
end

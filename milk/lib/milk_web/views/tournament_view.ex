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
        id: opponent.id,
        name: opponent.name,
        icon_path: opponent.icon_path,
        point: opponent.point,
        notification_number: opponent.notification_number,
        language: opponent.language,
        #email: opponent.auth.email,
        bio: opponent.bio
      },
      result: !is_nil(opponent)
    }
  end

  def render("opponent_team.json", %{opponent: opponent, leader: leader}) do
    %{
      opponent: %{
        id: opponent.id,
        name: leader.name,
        icon_path: leader.icon_path,
        rank: opponent.rank
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
      data: render_one(tournament, TournamentView, "tournament.json", msg: "Tournament was created!"),
      result: true
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
      discord_server_id: tournament.discord_server_id,
      game_id: tournament.game_id,
      game_name: tournament.game_name,
      enabled_coin_toss: tournament.enabled_coin_toss,
      event_date: tournament.event_date,
      start_recruiting: tournament.start_recruiting,
      deadline: tournament.deadline,
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
              coin_tail_field: tournament.custom_detail.coin_tail_field
            }
          end,
        event_date: tournament.event_date,
        enabled_coin_toss: tournament.enabled_coin_toss,
        enabled_map: tournament.enabled_map,
        start_recruiting: tournament.start_recruiting,
        deadline: tournament.deadline,
        discord_server_id: tournament.discord_server_id,
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
        rule: tournament.rule,
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
          end),
        maps:
          Enum.map(tournament.map, fn map ->
            %{
              id: map.id,
              name: map.name,
              state: map.state,
              icon_path: map.icon_path,
              tournament_id: map.tournament_id
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
      tournaments: render_many(tournaments, TournamentView, "tournament_info_include_entrants.json", as: :tournament_info),
      tournament_logs: render_many(tournament_log, TournamentView, "tournament_log.json", as: :tournament_log)
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
      data: render_many(tournaments_info, TournamentView, "tournament_info_include_entrants.json", as: :tournament_info),
      result: true
    }
  end

  def render("tournament_info_include_entrants.json", %{tournament_info: tournament}) do
    inspect(tournament)

    %{
      id: tournament.id,
      name: tournament.name,
      custom_detail:
        unless is_nil(tournament.custom_detail) do
          %{
            coin_head_field: tournament.custom_detail.coin_head_field,
            coin_tail_field: tournament.custom_detail.coin_tail_field
          }
        end,
      thumbnail_path: tournament.thumbnail_path,
      game_id: tournament.game_id,
      game_name: tournament.game_name,
      event_date: tournament.event_date,
      start_recruiting: tournament.start_recruiting,
      deadline: tournament.deadline,
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
      rule: tournament.rule,
      entrants:
        Enum.map(tournament.entrants, fn user ->
          %{
            id: user.id,
            name: user.name,
            icon_path: user.icon_path,
            point: user.point,
            notification_number: user.notification_number,
            language: user.language,
            #email: user.auth.email,
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
        enabled_map: tournament.enabled_map,
        event_date: tournament.event_date,
        start_recruiting: tournament.start_recruiting,
        deadline: tournament.deadline,
        platform: tournament.platform_id,
        capacity: tournament.capacity,
        password: tournament.password,
        description: tournament.description,
        master_id: tournament.master_id,
        is_team: tournament.is_team,
        team_size: tournament.team_size,
        url: tournament.url,
        create_time: tournament.create_time,
        update_time: tournament.update_time,
        rule: tournament.rule,
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

  def render("start.json", %{match_list: list, match_list_with_fight_result: list2, messages: messages, rule: rule}) do
    %{
      result: true,
      data: %{
        match_list: list,
        match_list_with_fight_result: list2,
        rule: rule,
        messages: Enum.map(messages, fn message ->
          %{
            state: message.state,
            user_id: message.user_id,
          }
        end)
      }
    }
  end

  def render("loser.json", %{list: list}) do
    %{
      result: true,
      updated_match_list: list
    }
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
        end),
      result: true
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

  # NOTE: フロント側で型を固定してある
  def render("match_info.json", %{match_info: match_info}) do
    %{
      tournament: if !is_nil(match_info.tournament) do
        # NOTE: IDはLogでも事前処理でちゃんとtournament固有のものが付けられている。
        # XXX: フロントの処理を見てちょっとずつ置き換えていかなければならないので、idやnameといった少ない情報しかここには入れていない
        %{
          name: match_info.tournament.name,
          id: match_info.tournament.id,
          master_id: match_info.tournament.master_id,
        }
      end,
      opponent: if !is_nil(match_info.opponent) do
        %{
          name: match_info.opponent.name,
          icon_path: match_info.opponent.icon_path,
          id: match_info.opponent.id
        }
      end,
      rank: match_info.rank,
      result: true,
      is_leader: match_info.is_leader,
      is_attacker_side: match_info.is_attacker_side,
      score: match_info.score,
      state: match_info.state,
      is_team: match_info.is_team,
      is_coin_head: match_info.is_coin_head,
      rule: match_info.rule,
      map:
        if match_info.map do
          %{
            state: match_info.map.state,
            name: match_info.map.name,
            icon_path: match_info.map.icon_path,
            id: match_info.map.id
          }
        end,
      custom_detail:
        if match_info.custom_detail do
          %{
            coin_head_field: match_info.custom_detail.coin_head_field,
            coin_tail_field: match_info.custom_detail.coin_tail_field
          }
        end
    }
  end

  def render("round_robin_match_list.json", %{match_list: %{"rematch_index" => rematch_index, "current_match_index" => current_match_index, "match_list" => match_list}}) do
    %{
      result: true,
      rematch_index: rematch_index,
      current_match_index: current_match_index,
      match_list: Enum.map(match_list, fn matches_in_round ->
        Enum.map(matches_in_round, fn {match_str, winner_id} ->
          %{
            match: match_str,
            winner_id: winner_id
          }
        end)
      end)
    }
  end

  # NOTE: フロント側で型を固定してある
  def render("maps.json", %{maps: maps}) do
    %{
      data:
        Enum.map(maps, fn map ->
          %{
            name: map.name,
            id: map.id,
            icon_path: map.icon_path,
            state: map.state
          }
        end)
    }
  end

  def render("error.json", %{error: error}) do
    %{result: false, error: error, data: nil}
  end

  def render("interaction_message.json", %{interaction_messages: messages, rule: rule}) do
    %{
      result: true,
      rule: rule,
      messages: Enum.map(messages, fn message ->
        %{
          state: message.state,
          user_id: message.user_id,
        }
      end)
    }
  end

  def render("claim.json", %{claim: claim}) do
    %{
      result: true,
      validated: claim.validated,
      completed: claim.completed,
      is_finished: claim.is_finished,
      opponent_user_id: claim.opponent_user_id,
      rule: claim.rule,
      messages: Enum.map(claim.interaction_messages, fn message ->
        %{
          state: message.state,
          user_id: message.user_id
        }
      end),
      user_id: claim.user_id
    }
  end
end

defmodule MilkWeb.TournamentView do
  use MilkWeb, :view

  alias MilkWeb.{
    TournamentView,
    UserView
  }

  def render("users.json", %{users: users}) do
    if users != [] do
      %{data: render_many(users, UserView, "user.json"), result: true}
    else
      %{data: nil, result: false}
    end
  end

  def render("index.json", %{tournament: tournament}) do
    %{data: render_many(tournament, TournamentView, "tournament.json"), result: true}
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

  def render("tournament.json", %{tournament: tournament}) do
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
      is_started: tournament.is_started
    }
  end

  def render("tournament_info.json", %{tournament: tournament, entrants: entrants}) do
    %{
      data: %{
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
        entrants:
          Enum.map(entrants, fn user ->
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
          end)
      },
      is_log: false,
      result: true
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
        entrants:
          Enum.map(tournament.entrants, fn user ->
            %{
              user_id: user.user_id
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
        entrants: entrants
      }) do
    %{
      data: %{
        master: render_one(master, UserView, "show.json"),
        assistants: render_many(assistants, UserView, "user.json"),
        entrants: render_many(entrants, UserView, "user.json")
      }
    }
  end

  def render("home.json", %{tournaments_info: tournaments_info}) do
    %{
      data:
        render_many(tournaments_info, TournamentView, "tournament_info_include_entrants.json",
          as: :tournament_info
        )
    }
  end

  def render("tournament_info_include_entrants.json", %{tournament_info: tournament}) do
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
        end)
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
        event_date: tournament.event_date,
        start_recruiting: tournament.start_recruiting,
        deadline: tournament.deadline,
        type: tournament.type,
        platform: tournament.platform_id,
        capacity: tournament.capacity,
        password: tournament.password,
        description: tournament.description,
        master_id: tournament.master_id,
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
      }
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

  # def render("error.json", %{error: error, msg: "Creating tournament failed"}) do
  def render("error.json", %{error: error}) do
    if error do
      %{result: false, error: error, data: nil}
    else
      %{result: false, error: nil, data: nil}
    end
  end
end

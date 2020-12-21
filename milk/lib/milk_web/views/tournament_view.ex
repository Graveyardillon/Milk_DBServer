defmodule MilkWeb.TournamentView do
  use MilkWeb, :view

  alias MilkWeb.TournamentView
  alias MilkWeb.UserView
  alias Milk.{Accounts, Tournaments}


  def render("users.json", %{users: users}) do
    if users != [] do
      %{data: render_many(users, UserView, "user.json"), result: true}
    else
      %{data: nil, result: false}
    end
  end

  def render("index.json", %{tournament: tournament}) do
    %{data: render_many(tournament, TournamentView, "tournament.json")}
  end

  def render("show.json", %{tournament: tournament}) do
    %{data: render_one(tournament, TournamentView, "tournament.json",
    msg: "Tournament was created!")}
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
      password: tournament.password,
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
        password: tournament.password,
        description: tournament.description,
        master_id: tournament.master_id,
        url: tournament.url,
        create_time: tournament.create_time,
        update_time: tournament.update_time,
        is_started: tournament.is_started,
        entrants: Enum.map(entrants, fn user ->
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
        tournament_id: tournament_log.tournament_id,
        winner_id: tournament_log.winner_id,
        master_id: tournament_log.master_id,
        name: tournament_log.name,
        url: tournament_log.url,
        type: tournament_log.type
      }
    }
  end

  def render("tournament_members.json", %{master: master, assistants: assistants, entrants: entrants}) do
    %{
      data: %{
        master: render_one(master, UserView, "show.json"),
        assistants: render_many(assistants, UserView, "user.json"),
        entrants: render_many(entrants, UserView, "user.json"),
      }
    }
  end

  def render("home.json", %{tournaments_info: tournaments_info}) do
    %{
      data: Enum.map(tournaments_info, fn info ->
        %{
          id: info.tournament.id,
          name: info.tournament.name,
          thumbnail_path: info.tournament.thumbnail_path,
          game_id: info.tournament.game_id,
          game_name: info.tournament.game_name,
          event_date: info.tournament.event_date,
          start_recruiting: info.tournament.start_recruiting,
          deadline: info.tournament.deadline,
          type: info.tournament.type,
          platform: info.tournament.platform_id,
          capacity: info.tournament.capacity,
          password: info.tournament.password,
          description: info.tournament.description,
          master_id: info.tournament.master_id,
          url: info.tournament.url,
          create_time: info.tournament.create_time,
          update_time: info.tournament.update_time,
          is_started: info.tournament.is_started,
          entrants: Enum.map(info.entrants, fn user ->
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
        followers: Enum.map(tournament.followers, fn follower ->
          %{
            id: follower.id,
            name: follower.name
          }
        end)
      }
    }
  end
  def render("match.json",%{list: list}) do
    %{data: %{match_list: list}}
  end
  def render("loser.json",%{list: list}) do
    %{updated_match_list: list}
  end

  def render("tournament_topics.json", %{topics: topics}) do
    map = Enum.map(topics, fn topic ->
            %{
              id: topic.id,
              chat_room_id: topic.chat_room_id,
              topic_name: topic.topic_name,
              tournament_id: topic.tournament_id
            }
          end)

    %{data: map}
  end

  # FIXME: Authは読み込んでないのでemailを返すようにしていない
  def render("masters.json", %{masters: masters}) do
    %{
      data: Enum.map(masters, fn master ->
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

  #def render("error.json", %{error: error, msg: "Creating tournament failed"}) do
  def render("error.json", %{error: error}) do
    if(error) do
      %{result: false, error: error, data: nil}
    else
      %{result: false, error: nil, data: nil}
    end
  end

  def create_message(error) do
    Enum.reduce(error, "",fn {key, value}, acc -> to_string(key) <> " "<> elem(value,0) <> ", "<> acc end)
  end
end

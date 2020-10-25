defmodule MilkWeb.TournamentView do
  use MilkWeb, :view
  alias MilkWeb.TournamentView
  alias MilkWeb.UserView
  alias Milk.Accounts

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
      deadline: tournament.deadline,
      type: tournament.type,
      capacity: tournament.capacity,
      password: tournament.password,
      live: tournament.live,
      join: tournament.join,
      description: tournament.description,
      master_id: tournament.master_id,
      url: tournament.url,
      create_time: tournament.create_time,
      update_time: tournament.update_time,
      master_data: render_one(Accounts.get_user(tournament.master_id), UserView, "show.json")
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
        deadline: tournament.deadline,
        type: tournament.type,
        capacity: tournament.capacity,
        password: tournament.password,
        live: tournament.live,
        join: tournament.join,
        description: tournament.description,
        master_id: tournament.master_id,
        url: tournament.url,
        create_time: tournament.create_time,
        update_time: tournament.update_time,
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
          deadline: info.tournament.deadline,
          type: info.tournament.type,
          capacity: info.tournament.capacity,
          password: info.tournament.password,
          live: info.tournament.live,
          join: info.tournament.join,
          description: info.tournament.description,
          master_id: info.tournament.master_id,
          url: info.tournament.url,
          create_time: info.tournament.create_time,
          update_time: info.tournament.update_time,
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
        deadline: tournament.deadline,
        type: tournament.type,
        capacity: tournament.capacity,
        password: tournament.password,
        live: tournament.live,
        join: tournament.join,
        description: tournament.description,
        master_id: tournament.master_id,
        url: tournament.url,
        create_time: tournament.create_time,
        update_time: tournament.update_time,
        master_data: render_one(Accounts.get_user(tournament.master_id), UserView, "show.json"),
        followers: Enum.map(tournament.followers, fn follower -> 
          follower.id
        end)
      }
    }
  end

  def render("match.json",%{list: list}) do
    %{matchlist: list}
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

  def render("error.json", %{error: error,msg: "Creating tournament failed"}) do
    if(error) do
      %{result: false, error: create_message(error), data: nil}
    else
      %{result: false, error: nil, data: nil}
    end
  end

  def create_message(error) do
    Enum.reduce(error, "",fn {key, value}, acc -> to_string(key) <> " "<> elem(value,0) <> ", "<> acc end)
  end
end

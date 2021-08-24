defmodule MilkWeb.ProfileView do
  use MilkWeb, :view
  alias MilkWeb.ProfileView
  alias MilkWeb.GameView

  def render("index.json", %{profiles: profiles}) do
    %{data: render_many(profiles, ProfileView, "profile.json")}
  end

  def render("show.json", %{profile: profile}) do
    %{data: render_one(profile, ProfileView, "profile.json")}
  end

  def render("profile.json", %{profile: profile}) do
    %{
      id: profile.id,
      user_id: profile.user_id,
      content_id: profile.content_id,
      content_type: profile.content_type
    }
  end

  def render("profile.json", %{
        user: user,
        games: games,
        records: records,
        service_reference: service_reference,
        external_services: external_services
      }) do
    %{
      data: %{
        id: user.id,
        name: user.name,
        icon_path: user.icon_path,
        bio: user.bio,
        win_count: user.win_count,
        gameList: render_many(games, GameView, "game.json"),
        records: render_many(records, ProfileView, "rank.json", as: :record),
        service_reference:
          unless is_nil(service_reference) do
            %{
              twitter_id: service_reference.twitter_id,
              riot_id: service_reference.riot_id
            }
          end,
        external_services:
          render_many(external_services, ProfileView, "external_service.json",
            as: :external_service
          )
      },
      result: true
    }
  end

  def render("records.json", %{records: records}) do
    %{data: render_many(records, ProfileView, "rank.json", as: :record)}
  end

  def render("rank.json", %{record: record}) do
    %{
      tournament: %{
        capacity: record.tournament_log.capacity,
        description: record.tournament_log.description,
        event_date: record.tournament_log.event_date,
        master_id: record.tournament_log.master_id,
        name: record.tournament_log.name,
        tournament_id: record.tournament_log.tournament_id,
        type: record.tournament_log.type,
        url: record.tournament_log.url,
        winner_id: record.tournament_log.winner_id
      },
      rank: record.rank
    }
  end

  def render("external_services.json", %{external_services: external_services}) do
    %{
      data:
        render_many(external_services, ProfileView, "external_service.json", as: :external_service)
    }
  end

  def render("external_service.json", %{external_service: external_service}) do
    %{
      content: external_service.content,
      id: external_service.id,
      name: external_service.name
    }
  end
end

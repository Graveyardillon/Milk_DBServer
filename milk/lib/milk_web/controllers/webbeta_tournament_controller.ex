defmodule MilkWeb.WebbetaTournamentController do
  @doc """
    Routeを分けるためのController。いつかTournamentControllerに移動させる。
  """
  # MARK: WEBBETA
  use MilkWeb, :controller

  plug :put_view, MilkWeb.TournamentView # NOTE: Use TournamentView

  import Common.Sperm

  alias Common.{
    Tools,
    FileUtils
  }

  alias Milk.{
    Accounts,
    Tournaments
  }

  alias Milk.Tournaments.{
    Tournament
  }

  def browse(conn, %{"date_offset" => date_offset, "offset" => offset}) do
    tournaments = Tournaments.browse(date_offset, offset)
    render(conn, "list_info.json", tournaments: tournaments)
  end
  def browse(conn, %{"user_id" => user_id, "date_offset" => date_offset, "offset" => offset}) do
    tournaments = Tournaments.browse(date_offset, offset, user_id)
    render(conn, "list_info.json", tournaments: tournaments)
  end

  @doc """
    params:
      offset: int
      tags: array of tag_id
      date_from: date
      date_to : date
      rule: basic | flipban | flipban_roundrobin
  """
  def browse_filter(conn, params) do
    tournaments = Tournaments.browse_filter(params)
    render(conn, "list_info.json", tournaments: tournaments)
  end

  def info(conn, %{"id" => id}) do
    with %Tournament{} = tournament <- Tournaments.get_info(id) do
      render(conn, "info.json", tournament: tournament)
    else
      _ -> json(conn, %{msg: "tournament not found"})
    end
  end

  @doc """
    大会に関するすべての情報 基本使わない
  """
  def detailed_info(conn, %{"id" => id}) do
    with %Tournament{} = tournament <- Tournaments.get_detailed_info(id) do
      render(conn, "detailed_info.json", tournament: tournament)
    else
      _ -> json(conn, %{msg: "tournament not found"})
    end
  end

end

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

  def browse(conn, %{"user_id" => user_id, "date_offset" => date_offset, "offset" => offset}) do
    tournaments = Tournaments.browse(date_offset, offset, user_id)
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

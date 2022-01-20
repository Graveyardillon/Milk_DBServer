defmodule MilkWeb.EntrantView do
  use MilkWeb, :view

  alias Common.Tools
  alias MilkWeb.{
    EntrantView,
    UserView
  }

  def render("entrants.json", %{entrants: entrants}) do
    render_many(entrants, EntrantView, "entrant.json")
  end

  def render("show.json", %{entrant: entrant}) do
    %{result: true, data: render_one(entrant, EntrantView, "entrant.json")}
  end

  def render("entrant.json", %{entrant: entrant}) do
    %{
      id: entrant.id,
      rank: entrant.rank,
      create_time: entrant.create_time,
      tournament_id: entrant.tournament_id, # TODO: remove
      user_id: entrant.user_id, # TODO: remove
      user: render_one(entrant, UserView, "user.json", as: :user),
      update_time: entrant.update_time
    }
  end

  def render("error.json", %{error: error}) do
    if error do
      %{result: false, error: error, data: nil}
    else
      %{result: false, error: nil, data: nil}
    end
  end

  def render("multierror.json", %{error: error}) do
    %{result: false, error: Tools.create_error_message(error), data: nil}
  end

  def render("rank.json", %{rank: rank}) do
    %{data: %{rank: rank}}
  end
end

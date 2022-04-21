defmodule MilkWeb.EntrantController do
  use MilkWeb, :controller

  alias Common.Tools

  alias Milk.Tournaments

  alias Milk.Tournaments.{
    Entrant,
    Team,
    Tournament
  }

  @doc """
  Create an entrant.
  """
  def create(conn, %{"entrant" => entrant_params}) do
    entrant_params
    |> Tournaments.create_entrant()
    |> case do
      {:ok, %Entrant{} = entrant} -> render(conn, "show.json", entrant: entrant)
      {:error, error}             -> render(conn, "error.json", error: error)
    end
  end

  def create(conn, %{"tournament_id" => tournament_id, "name" => name}) do
    tournament_id
    |> Tools.to_integer_as_needed()
    |> Tournaments.create_dummy_entrant(name)
    |> case do
      {:ok, %Entrant{} = entrant} -> render(conn, "show.json", entrant: entrant)
      {:error, error}             -> render(conn, "error.json", error: error)
    end
  end

  @doc """
  Shows an entrant.
  """
  def show(conn, %{"id" => id}) do
    entrant = Tournaments.get_entrant(id)

    if entrant do
      render(conn, "show.json", entrant: entrant)
    else
      render(conn, "error.json", error: nil)
    end
  end

  @doc """
  Update an entrant.
  """
  def update(conn, %{"id" => id, "entrant" => entrant_params}) do
    with entrant when not is_nil(entrant) <- Tournaments.get_entrant(id),
         {:ok, entrant}                   <- Tournaments.update_entrant(entrant, entrant_params) do
      render(conn, "show.json", entrant: entrant)
    else
      {:error, error} -> render(conn, "error.json", error: error)
      nil             -> render(conn, "error.json", error: nil)
    end
  end

  @doc """
  Delete an entrant.
  """
  def delete(conn, %{"tournament_id" => tournament_id, "user_id" => user_id}) do
    case Tournaments.delete_entrant(tournament_id, user_id) do
      {:ok, entrant}  -> render(conn, "show.json", entrant: entrant)
      {:error, error} -> json(conn, %{error: error, result: false})
    end
  end

  @doc """
  Show rank.
  """
  def show_rank(conn, %{"tournament_id" => tournament_id, "user_id" => user_id}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    user_id = Tools.to_integer_as_needed(user_id)

    tournament_id
    |> Tournaments.get_tournament()
    |> get_rank_by_tournament(user_id)
    |> case do
      {:ok, rank}     -> render(conn, "rank.json", rank: rank)
      {:error, error} -> render(conn, "error.json", error: error)
    end
  end

  defp get_rank_by_tournament(%Tournament{is_team: true, id: tournament_id}, user_id) do
    tournament_id
    |> Tournaments.get_team_by_tournament_id_and_user_id(user_id)
    |> get_rank_by_team()
  end

  defp get_rank_by_tournament(%Tournament{is_team: false, id: tournament_id}, user_id),
    do: Tournaments.get_rank(tournament_id, user_id)

  defp get_rank_by_tournament(nil, _), do: {:error, "tournament is nil"}

  defp get_rank_by_team(%Team{} = team), do: {:ok, team.rank}
  defp get_rank_by_team(nil), do: {:error, "team is nil"}

  @doc """
  promote rank.
  """
  def promote(conn, attrs) do
    case Tournaments.promote_rank(attrs) do
      {:ok, entrant}  -> render(conn, "rank.json", rank: entrant.rank)
      {:error, error} -> render(conn, "error.json", error: error)
    end
  end
end

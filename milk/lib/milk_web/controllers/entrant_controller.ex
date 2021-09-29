defmodule MilkWeb.EntrantController do
  use MilkWeb, :controller

  import Common.Sperm

  alias Common.Tools

  alias Milk.{
    Accounts,
    Tournaments
  }

  alias Milk.Tournaments.Entrant

  # action_fallback MilkWeb.FallbackController

  def index(conn, _params) do
    entrant = Tournaments.list_entrant()

    if entrant do
      render(conn, "index.json", entrant: entrant)
    else
      render(conn, "error.json", error: nil)
    end
  end

  @doc """
  Create an entrant.
  """
  def create(conn, %{"entrant" => entrant_params}) do
    entrant_params
    |> Tournaments.create_entrant()
    |> case do
      {:ok, %Entrant{} = entrant} ->
        action_history(entrant)

        conn
        # |> put_status(:created)
        # |> put_resp_header("location", Routes.entrant_path(conn, :show, entrant))
        |> render("show.json", entrant: entrant)

      {:error, error} ->
        render(conn, "error.json", error: error)

      {:multierror, error} ->
        render(conn, "multierror.json", error: error)

      _ ->
        render(conn, "error.json", error: nil)
    end
  end

  defp action_history(entrant) do
    {:ok, tournament} = Tournaments.get_tournament_including_logs(entrant.tournament_id)

    %{"user_id" => entrant.user_id, "game_name" => tournament.game_name, "score" => 5}
    |> Accounts.gain_score()
  end

  @doc """
  Shows an entrant.
  """
  def show(conn, %{"id" => id}) do
    entrant = Tournaments.get_entrant!(id)

    if entrant do
      render(conn, "show.json", entrant: entrant)
    else
      render(conn, "error.json", error: nil)
    end
  end

  def update(conn, %{"id" => id, "entrant" => entrant_params}) do
    entrant = Tournaments.get_entrant!(id)

    if entrant do
      case Tournaments.update_entrant(entrant, entrant_params) do
        {:ok, %Entrant{} = entrant} ->
          render(conn, "show.json", entrant: entrant)

        {:error, error} ->
          render(conn, "error.json", error: error)

        _ ->
          render(conn, "error.json", error: nil)
      end
    else
      render(conn, "error.json", error: nil)
    end
  end

  def delete(conn, %{"tournament_id" => tournament_id, "user_id" => user_id}) do
    case Tournaments.delete_entrant(tournament_id, user_id) do
      {:ok, entrant} ->
        render(conn, "show.json", entrant: entrant)

      {:error, error} ->
        json(conn, %{error: error, result: false})
    end
  end

  def show_rank(conn, %{"tournament_id" => tournament_id, "user_id" => user_id}) do
    tournament_id = Tools.to_integer_as_needed(tournament_id)
    user_id = Tools.to_integer_as_needed(user_id)

    tournament = Tournaments.get_tournament(tournament_id)

    if tournament do
      tournament
      |> Map.get(:is_team)
      |> if do
        tournament_id
        |> Tournaments.get_team_by_tournament_id_and_user_id(user_id)
        ~> team
        |> if do
          {:ok, team.rank}
        else
          {:error, "team is nil"}
        end
      else
        Tournaments.get_rank(tournament_id, user_id)
      end
    else
      {:error, "tournament is nil"}
    end
    |> case do
      {:ok, rank} -> render(conn, "rank.json", rank: rank)
      {:error, msg} -> render(conn, "error.json", error: msg)
    end
  end

  def promote(conn, attrs) do
    case Tournaments.promote_rank(attrs) do
      {:ok, entrant} -> render(conn, "rank.json", rank: entrant.rank)
      {:error, error} -> render(conn, "error.json", error: error)
    end
  end
end

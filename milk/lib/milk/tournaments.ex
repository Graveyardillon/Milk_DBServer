defmodule Milk.Tournaments do
  @moduledoc """
  The Tournaments context.
  """

  import Ecto.Query, warn: false
  alias Milk.Repo
  alias Ecto.Multi

  alias Milk.Tournaments.Tournament
  alias Milk.Tournaments.Entrant
  alias Milk.Tournaments.Assistant
  alias Milk.Games.Game
  alias Milk.Accounts.User
  alias Milk.Log.{TournamentLog, EntrantLog, AssistantLog}

  @doc """
  Returns the list of tournament.

  ## Examples

      iex> list_tournament()
      [%Tournament{}, ...]

  """
  def list_tournament do
    Repo.all(Tournament)
  end

  def game_tournament(attrs) do
    Repo.all(from t in Tournament, where: t.game_id == ^attrs["game_id"])
  end

  @doc """
  Gets a single tournament.

  Raises `Ecto.NoResultsError` if the Tournament does not exist.

  ## Examples

      iex> get_tournament!(123)
      %Tournament{}

      iex> get_tournament!(456)
      ** (Ecto.NoResultsError)

  """
  def get_tournament!(id), do: Repo.get!(Tournament, id)

  @doc """
  Creates a tournament.

  ## Examples

      iex> create_tournament(%{field: value})
      {:ok, %Tournament{}}

      iex> create_tournament(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tournament(attrs \\ %{}) do
    if (Repo.exists?(from u in User, where: u.id == ^attrs["master_id"]) 
    and Repo.exists?(from u in Game, where: u.id == ^attrs["game_id"])) do
      case %Tournament{master_id: attrs["master_id"], game_id: attrs["game_id"]}
      |> Tournament.changeset(attrs)
      |> Repo.insert() do
        {:ok, tournament} ->
          {:ok, tournament}
        {:error, error} ->
          {:error, error.errors}
        _ ->
          {:error, nil}
      end
    else
      {:error, nil}
    end
  end

  @doc """
  Updates a tournament.

  ## Examples

      iex> update_tournament(tournament, %{field: new_value})
      {:ok, %Tournament{}}

      iex> update_tournament(tournament, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tournament(%Tournament{} = tournament, attrs) do
    case tournament
    |> Tournament.changeset(attrs)
    |> Repo.update() do
      {:ok, tournament} ->
        {:ok, tournament}
      {:error, error} ->
        {:error, error.errors}
      _ ->
        {:error, nil}
    end
  end

  @doc """
  Deletes a tournament.

  ## Examples

      iex> delete_tournament(tournament)
      {:ok, %Tournament{}}

      iex> delete_tournament(tournament)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tournament(id) do
    tournament = Repo.one(from t in Tournament, left_join: a in assoc(t, :assistant),
    left_join: e in assoc(t, :entrant), where: t.id == ^id,
    preload: [assistant: a, entrant: e])

    entrant = Enum.map(tournament.entrant, fn x -> %{rank: x.rank, user_id: x.user_id, 
      tournament_id: x.tournament_id, update_time: x.update_time, create_time: x.create_time} end)
    if entrant, do: Repo.insert_all(EntrantLog, entrant)

    assistant = Enum.map(tournament.assistant, fn x -> %{user_id: x.user_id, tournament_id: x.tournament_id, 
    update_time: x.update_time, create_time: x.create_time} end)
    if assistant, do: Repo.insert_all(AssistantLog, assistant)

    TournamentLog.changeset(%TournamentLog{}, Map.from_struct(tournament))
    |> Repo.insert
    |> IO.inspect
    Repo.delete(tournament)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tournament changes.

  ## Examples

      iex> change_tournament(tournament)
      %Ecto.Changeset{data: %Tournament{}}

  """
  def change_tournament(%Tournament{} = tournament, attrs \\ %{}) do
    Tournament.changeset(tournament, attrs)
  end

  @doc """
  Returns the list of entrant.

  ## Examples

      iex> list_entrant()
      [%Entrant{}, ...]

  """
  def list_entrant do
    Repo.all(Entrant)
  end

  @doc """
  Gets a single entrant.

  Raises `Ecto.NoResultsError` if the Entrant does not exist.

  ## Examples

      iex> get_entrant!(123)
      %Entrant{}

      iex> get_entrant!(456)
      ** (Ecto.NoResultsError)

  """
  def get_entrant!(id), do: Repo.get!(Entrant, id)

  @doc """
  Creates a entrant.

  ## Examples

      iex> create_entrant(%{field: value})
      {:ok, %Entrant{}}

      iex> create_entrant(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_entrant(attrs \\ %{}) do
    if (Repo.exists?(from u in User, where: u.id == ^attrs["user_id"])) do 
      case Multi.new()
      |> Multi.run(:tournament, fn repo, _ ->
        {:ok, repo.get(Tournament, attrs["tournament_id"])}
      end)
      |> Multi.insert(:entrant, fn _ ->
        %Entrant{user_id: attrs["user_id"], tournament_id: attrs["tournament_id"]}
        |> Entrant.changeset(attrs)
      end)
      |> Multi.update(:update, fn %{tournament: tournament} ->
        IO.inspect tournament.count
        Tournament.changeset(tournament, %{count: tournament.count + 1}) 
        |> IO.inspect
      end)
      |> Repo.transaction() do
        {:ok, entrant} ->
          {:ok, entrant.entrant}
        {:error, _, error, data} -> 
          {:error, error.errors}
        _ ->
          {:error, nil}
      end
    else
      {:error, nil}
    end
  end

  @doc """
  Updates a entrant.

  ## Examples

      iex> update_entrant(entrant, %{field: new_value})
      {:ok, %Entrant{}}

      iex> update_entrant(entrant, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_entrant(%Entrant{} = entrant, attrs) do
    case entrant
    |> Entrant.changeset(attrs)
    |> Repo.update() do
    {:ok, chat_member} ->
      {:ok, chat_member}
    {:error, error} ->
      {:error, error.errors}
    _ ->
      {:error, nil}
    end
  end

  @doc """
  Deletes a entrant.

  ## Examples

      iex> delete_entrant(entrant)
      {:ok, %Entrant{}}

      iex> delete_entrant(entrant)
      {:error, %Ecto.Changeset{}}

  """
  def delete_entrant(%Entrant{} = entrant) do
    EntrantLog.changeset(%EntrantLog{}, Map.from_struct(entrant))
    |> Repo.insert()
    tournament = Repo.get(Tournament, entrant.tournament_id)
    Tournament.changeset(tournament, %{count: tournament.count -1})
    |> Repo.update()
    Repo.delete(entrant)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking entrant changes.

  ## Examples

      iex> change_entrant(entrant)
      %Ecto.Changeset{data: %Entrant{}}

  """
  def change_entrant(%Entrant{} = entrant, attrs \\ %{}) do
    Entrant.changeset(entrant, attrs)
  end

  @doc """
  Returns the list of assistant.

  ## Examples

      iex> list_assistant()
      [%Assistant{}, ...]

  """
  def list_assistant do
    Repo.all(Assistant)
  end

  @doc """
  Gets a single assistant.

  Raises `Ecto.NoResultsError` if the Assistant does not exist.

  ## Examples

      iex> get_assistant!(123)
      %Assistant{}

      iex> get_assistant!(456)
      ** (Ecto.NoResultsError)

  """
  def get_assistant!(id), do: Repo.get!(Assistant, id)

  @doc """
  Creates a assistant.

  ## Examples

      iex> create_assistant(%{field: value})
      {:ok, %Assistant{}}

      iex> create_assistant(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_assistant(attrs \\ %{}) do
    if (Repo.exists?(from u in User, where: u.id == ^attrs["user_id"]) 
    and Repo.exists?(from t in Tournament, where: t.id == ^attrs["tournament_id"])) do
      case %Assistant{user_id: attrs["user_id"], tournament_id: attrs["tournament_id"]}
      |> Repo.insert() do
      {:ok, assistant} ->
        {:ok, assistant}
      {:error, error} ->
        {:error, error.errors}
      _ ->
        {:error, nil}
      end
    end
  end

  @doc """
  Updates a assistant.

  ## Examples

      iex> update_assistant(assistant, %{field: new_value})
      {:ok, %Assistant{}}

      iex> update_assistant(assistant, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_assistant(%Assistant{} = assistant, attrs) do
    case assistant
    |> Assistant.changeset(attrs)
    |> Repo.update() do
      {:ok, assistant} ->
        {:ok, assistant}
      {:error, error} ->
        {:error, error.errors}
      _ ->
        {:error, nil}
    end
  end

  @doc """
  Deletes a assistant.

  ## Examples

      iex> delete_assistant(assistant)
      {:ok, %Assistant{}}

      iex> delete_assistant(assistant)
      {:error, %Ecto.Changeset{}}

  """
  def delete_assistant(%Assistant{} = assistant) do
    AssistantLog.changeset(%AssistantLog{}, Map.from_struct(assistant))
    |> Repo.insert()
    Repo.delete(assistant)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking assistant changes.

  ## Examples

      iex> change_assistant(assistant)
      %Ecto.Changeset{data: %Assistant{}}

  """
  def change_assistant(%Assistant{} = assistant, attrs \\ %{}) do
    Assistant.changeset(assistant, attrs)
  end


end

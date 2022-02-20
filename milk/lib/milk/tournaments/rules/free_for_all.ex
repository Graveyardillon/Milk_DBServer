defmodule Milk.Tournaments.Rules.FreeForAll do
  @moduledoc """

  """
  import Ecto.Query, warn: false

  alias Milk.Tournaments.Rules.FreeForAll.Information
  alias Milk.Repo

  @spec create_free_for_all_information(map()) :: {:ok, Information.t()} | {:error, Ecto.Changeset.t()}
  def create_free_for_all_information(attrs \\ %{}) do
    %Information{}
    |> Information.changeset(attrs)
    |> Repo.insert()
  end
end

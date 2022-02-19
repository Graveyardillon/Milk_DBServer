defmodule Milk.Tournaments.Rules.FreeForAll.Round.Information do
  @moduledoc """
  個人戦
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Rules.FreeForAll.Round.Table
  alias Milk.Accounts.User

  schema "tournaments_rules_freeforall_round_information" do
    belongs_to :table, Table
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(attrs, information) do
    information
    |> cast(attrs, [:table_id, :user_id])
    |> foreign_key_constraint(:table_id)
    |> foreign_key_constraint(:user_id)
  end
end

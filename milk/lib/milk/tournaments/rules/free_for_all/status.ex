defmodule Milk.Tournaments.Rules.FreeForAll.Status do
  @moduledoc """
  現在のステータス（個人）
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Tournament
  alias Milk.Accounts.User

  schema "tournaments_rules_freeforall_status" do
    field :current_round_index, :integer, default: 0
    field :current_match_index, :integer, default: 0

    belongs_to :tournament, Tournament
    belongs_to :user_id, User

    timestamps()
  end

  @doc false
  def changeset(status, attrs) do
    status
    |> cast(attrs, [:current_round_index, :current_match_index, :tournament_id, :user_id])
    |> foreign_key_constraint(:tournament_id)
    |> foreign_key_constraint(:user_id)
  end
end

defmodule Milk.Tournaments.Rules.FreeForAll.Status do
  @moduledoc """
  現在のステータス（個人）
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Tournament
  alias Milk.Accounts.User

  @type t :: %__MODULE__{
    current_round_index: :integer,
    current_match_index: :integer,
    tournament_id: :integer,
    user_id: :integer,
    # NOTE: timestamps
    create_time: any(),
    update_time: any()
  }

  schema "tournaments_rules_freeforall_status" do
    field :current_round_index, :integer, default: 0
    field :current_match_index, :integer, default: 0

    belongs_to :tournament, Tournament
    belongs_to :user, User

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

defmodule Milk.Tournaments.Progress.TeamRoundRobinWinCount do
  @moduledoc """
  総当たり戦のときのチーム勝利数を管理するテーブル
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Team

  @type t :: %__MODULE__{
    win_count: integer(),
    team_id: integer(),
    # NOTE: timestamps
    create_time: any(),
    update_time: any()
  }

  schema "team_round_robin_win_count" do
    field :win_count, :integer, default: 0
    belongs_to :team, Team

    timestamps()
  end

  @doc false
  def changeset(map, attrs) do
    map
    |> cast(attrs, [:win_count, :team_id])
  end
end

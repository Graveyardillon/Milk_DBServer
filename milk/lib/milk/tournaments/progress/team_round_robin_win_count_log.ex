defmodule Milk.Tournaments.Progress.TeamRoundRobinWinCountLog do
  @moduledoc """
  総当たり戦のときのチーム勝利数ログを管理するテーブル
  """

  use Milk.Schema

  import Ecto.Changeset

  schema "team_round_robin_win_count_log" do
    field :team_id, :integer
    field :win_count, :integer

    timestamps()
  end

  @doc false
  def changeset(map, attrs) do
    map
    |> cast(attrs, [:win_count, :team_id])
  end
end

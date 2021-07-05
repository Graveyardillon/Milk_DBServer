defmodule Milk.Log.TeamLog do
  use Milk.Schema

  import Ecto.Changeset

  schema "team_log" do
    field :name, :string
    field :size, :integer
    field :tournament_id, :integer

    timestamps()
  end

  @doc false
  def changeset(team_log, attrs) do
    team_log
    |> cast(attrs, [:name, :size, :team_log])
  end
end

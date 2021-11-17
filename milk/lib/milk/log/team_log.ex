defmodule Milk.Log.TeamLog do
  @moduledoc """
  Team log schema.
  """
  use Milk.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          icon_path: String.t() | nil,
          is_confirmed: boolean(),
          name: String.t() | nil,
          rank: integer() | nil,
          size: integer() | nil,
          team_id: integer(),
          tournament_id: integer(),
          # NOTE: timestamps
          create_time: any(),
          update_time: any()
        }

  schema "team_log" do
    field :icon_path, :string
    field :is_confirmed, :boolean, default: false
    field :name, :string
    field :rank, :integer
    field :size, :integer
    field :team_id, :integer
    field :tournament_id, :integer

    timestamps()
  end

  @doc false
  def changeset(team_log, attrs) do
    team_log
    |> cast(attrs, [:icon_path, :is_confirmed, :name, :rank, :size, :team_id, :tournament_id])
  end
end

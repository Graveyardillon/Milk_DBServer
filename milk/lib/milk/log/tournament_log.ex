defmodule Milk.Log.TournamentLog do
  @moduledoc """
  Tournameng log schema.
  """
  use Milk.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          capacity: integer(),
          count: integer(),
          deadline: any(),
          description: String.t() | nil,
          event_date: any(),
          game_id: integer(),
          game_name: String.t(),
          is_deleted: boolean(),
          is_started: boolean(),
          is_team: boolean(),
          master_id: integer(),
          name: String.t(),
          team_size: integer() | nil,
          thumbnail_path: String.t() | nil,
          tournament_id: integer(),
          type: integer(),
          url: String.t() | nil,
          winner_id: integer(),
          # NOTE: timestamps
          create_time: any(),
          update_time: any()
        }

  schema "tournaments_log" do
    field :capacity, :integer
    field :count, :integer
    field :deadline, EctoDate
    field :description, :string
    field :event_date, EctoDate
    field :game_id, :integer
    field :game_name, :string
    field :is_deleted, :boolean
    field :is_started, :boolean
    field :is_team, :boolean
    field :master_id, :integer
    field :name, :string
    field :team_size, :integer
    field :thumbnail_path, :string
    field :tournament_id, :integer
    field :type, :integer
    field :url, :string
    field :winner_id, :integer

    timestamps()
  end

  @doc false
  def changeset(tournament, attrs) do
    tournament
    |> cast(attrs, [
      :tournament_id,
      :name,
      :game_id,
      :game_name,
      :event_date,
      :capacity,
      :count,
      :description,
      :master_id,
      :winner_id,
      :deadline,
      :type,
      :url,
      :team_size,
      :thumbnail_path,
      :is_started,
      :is_team,
      :is_deleted
    ])
    |> validate_required([:name])
  end
end

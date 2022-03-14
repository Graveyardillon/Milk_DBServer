defmodule Milk.Log.TournamentLog do
  @moduledoc """
  Tournameng log schema.
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Platforms.Platform

  @type t :: %__MODULE__{
          capacity: integer(),
          count: integer(),
          deadline: any(),
          description: String.t() | nil,
          discord_server_id: String.t(),
          enabled_coin_toss: boolean(),
          enabled_map: boolean(),
          event_date: any(),
          game_id: integer(),
          game_name: String.t(),
          is_deleted: boolean(),
          is_started: boolean(),
          is_team: boolean(),
          master_id: integer(),
          name: String.t(),
          password: String.t(),
          platform_id: :integer,
          rule: String.t() | nil,
          start_recruiting: any(),
          team_size: integer() | nil,
          thumbnail_path: String.t() | nil,
          tournament_id: integer(),
          type: integer(),
          url: String.t() | nil,
          url_token: String.t() | nil,
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
    field :discord_server_id, :string
    field :enabled_coin_toss, :boolean, default: false
    field :enabled_map, :boolean, default: false
    field :event_date, EctoDate
    field :game_id, :integer
    field :game_name, :string
    field :is_deleted, :boolean
    field :is_started, :boolean
    field :is_team, :boolean
    field :master_id, :integer
    field :name, :string
    field :password, :string
    field :rule, :string
    field :start_recruiting, EctoDate
    field :team_size, :integer
    field :thumbnail_path, :string
    field :tournament_id, :integer
    field :type, :integer
    field :url, :string
    field :url_token, :string
    field :winner_id, :integer

    belongs_to :platform, Platform

    timestamps()
  end

  @doc false
  def changeset(tournament, attrs) do
    tournament
    |> cast(attrs, [
      :capacity,
      :count,
      :deadline,
      :description,
      :discord_server_id,
      :enabled_coin_toss,
      :enabled_map,
      :event_date,
      :game_id,
      :game_name,
      :is_deleted,
      :is_started,
      :is_team,
      :master_id,
      :name,
      :password,
      :platform_id,
      :rule,
      :start_recruiting,
      :team_size,
      :thumbnail_path,
      :tournament_id,
      :type,
      :url,
      :url_token,
      :winner_id
    ])
    |> validate_required([:name])
    |> foreign_key_constraint(:platform_id)
  end
end

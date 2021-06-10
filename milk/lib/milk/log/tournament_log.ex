defmodule Milk.Log.TournamentLog do
  use Milk.Schema

  import Ecto.Changeset

  schema "tournaments_log" do
    field :capacity, :integer
    field :deadline, EctoDate
    field :description, :string
    field :event_date, EctoDate
    field :game_id, :integer
    field :game_name, :string
    field :is_deleted, :boolean
    field :is_started, :boolean
    field :master_id, :integer
    field :name, :string
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
      :description,
      :master_id,
      :winner_id,
      :deadline,
      :type,
      :url,
      :thumbnail_path
    ])
    |> validate_required([:name])
  end
end

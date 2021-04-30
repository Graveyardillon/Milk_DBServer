defmodule Milk.Log.TournamentLog do
  use Milk.Schema

  import Ecto.Changeset

  # FIXME: master_idとかは外部キーにしないほうがいいかしっかり検証する
  schema "tournaments_log" do
    field :name, :string
    field :event_date, EctoDate
    field :capacity, :integer
    field :description, :string
    field :deadline, EctoDate
    field :type, :integer
    field :url, :string
    field :tournament_id, :integer
    field :game_id, :integer
    field :game_name, :string
    field :master_id, :integer
    field :winner_id, :integer
    field :thumbnail_path, :string
    field :is_deleted, :boolean
    field :is_started, :boolean

    timestamps()
  end

  @doc false
  def changeset(tournament, attrs) do
    tournament
    |> cast(attrs, [:tournament_id, :name, :game_id, :game_name, :event_date, :capacity, :description, :master_id, :winner_id, :deadline, :type, :url, :thumbnail_path])
    |> validate_required([:name])
  end
end

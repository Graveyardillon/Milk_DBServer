defmodule Milk.Log.TournamentLog do
  use Milk.Schema
  import Ecto.Changeset

  # FIXME: master_idとかは外部キーにしないほうがいいかしっかり検証する
  schema "tournament_log" do
    field :capacity, :integer
    field :deadline, EctoDate
    field :description, :string
    field :event_date, EctoDate
    field :game_id, :integer
    field :tournament_id, :integer
    field :master_id, :integer
    field :winner_id, :integer
    field :name, :string
    field :type, :integer
    field :url, :string

    timestamps()
  end

  @doc false
  def changeset(tournament, attrs) do
    tournament
    |> cast(attrs, [:tournament_id, :name, :game_id, :event_date, :capacity, :description, :master_id, :winner_id, :deadline, :type, :url])
    |> validate_required([:name])
  end
end

defmodule Milk.Log.TournamentLog do
  use Milk.Schema
  import Ecto.Changeset

  schema "tournament_log" do
    field :capacity, :integer
    field :deadline, EctoDate
    field :description, :string
    field :event_date, EctoDate
    field :game_id, :integer
    field :master_id, :integer
    field :name, :string
    field :type, :integer
    field :url, :string

    field :create_time, EctoDate
    field :update_time, EctoDate
  end

  @doc false
  def changeset(tournament, attrs) do
    tournament
    |> cast(attrs, [:name, :game_id, :event_date, :capacity, :description, :master_id, :deadline, :type, :url, :create_time, :update_time])
    # |> validate_required([:name, :game_id, :event_date, :capacity, :description, :master_id, :deadline, :type, :url])
  end
end

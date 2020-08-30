defmodule Milk.Log.EntrantLog do
  use Milk.Schema
  import Ecto.Changeset

  schema "entrant_log" do
    field :rank, :integer
    field :tournament_id, :integer
    field :user_id, :integer

    field :create_time, EctoDate
    field :update_time, EctoDate
  end

  @doc false
  def changeset(entrant_log, attrs) do
    entrant_log
    |> cast(attrs, [:tournament_id, :user_id, :rank, :create_time, :update_time])
    |> validate_required([:tournament_id, :user_id, :rank])
  end
end

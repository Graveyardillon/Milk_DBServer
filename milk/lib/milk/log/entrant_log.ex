defmodule Milk.Log.EntrantLog do
  use Milk.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          entrant_id: integer(),
          rank: integer() | nil,
          show_on_profile: boolean(),
          tournament_id: integer(),
          user_id: integer(),
          create_time: any(),
          update_time: any()
        }

  schema "entrants_log" do
    field :entrant_id, :integer
    field :rank, :integer
    field :show_on_profile, :boolean
    field :tournament_id, :integer
    field :user_id, :integer

    field :create_time, EctoDate
    field :update_time, EctoDate
  end

  @doc false
  def changeset(entrant_log, attrs) do
    entrant_log
    |> cast(attrs, [
      :entrant_id,
      :rank,
      :show_on_profile,
      :tournament_id,
      :user_id,
      :create_time,
      :update_time
    ])
    |> validate_required([:entrant_id, :tournament_id])
  end
end

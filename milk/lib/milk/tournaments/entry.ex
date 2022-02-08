defmodule Milk.Tournaments.Entry do
  @moduledoc """
  大会のエントリー情報のための中間テーブル
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Tournament

  @type t :: %__MODULE__{
    tournament_id: integer(),
    # NOTE: timestamps
    create_time: any(),
    update_time: any()
  }

  schema "entries" do
    belongs_to :tournament, Tournament

    timestamps()
  end

  @doc false
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:tournament_id])
    |> validate_required([:tournament_id])
  end
end

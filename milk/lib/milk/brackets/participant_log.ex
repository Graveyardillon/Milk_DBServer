defmodule Milk.Brackets.ParticipantLog do
  use Milk.Schema

  alias Milk.Brackets.BracketLog

  schema "bracket_participants_log" do
    field :name, :string
    field :rank, :integer
    field :participant_id, :integer

    belongs_to :bracket, BracketLog

    timestamps()
  end

  def changeset(participant_log, attrs) do
    participant_log
    |> cast(attrs, [:name, :rank, :bracket_id, :participant_id])
  end
end

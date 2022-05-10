defmodule Milk.Brackets.ParticipantLog do
  use Milk.Schema

  alias Milk.Brackets.BracketLog

  schema "bracket_participants_log" do
    field :name, :string

    belongs_to :bracket, BracketLog

    timestamps()
  end

  def changeset(participant_log, attrs) do
    participant_log
    |> cast(attrs, [:name, :bracket_id])
  end
end

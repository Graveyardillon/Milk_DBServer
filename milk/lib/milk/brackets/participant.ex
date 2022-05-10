defmodule Milk.Brackets.Participant do
  @moduledoc """
  トーナメント表の参加者
  """
  use Milk.Schema

  alias Milk.Brackets.Bracket

  schema "bracket_participants" do
    field :name, :string

    belongs_to :bracket, Bracket

    timestamps()
  end

  def changeset(participant, attrs) do
    participant
    |> cast(attrs, [:name, :bracket_id])
  end
end

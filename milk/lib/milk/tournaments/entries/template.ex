defmodule Milk.Tournaments.Entries.Template do
  use Milk.Schema
  import Ecto.Changeset

  schema "entry_templates" do
    field :title, :string
    field :tournament_id, :id

    timestamps()
  end

  @doc false
  def changeset(template, attrs) do
    template
    |> cast(attrs, [:title, :tournament_id])
    |> validate_required([:title])
  end
end

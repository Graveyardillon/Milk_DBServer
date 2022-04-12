defmodule Milk.Tournaments.Entries.Template do
  use Milk.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
    title: :string,
    tournament_id: :integer,
    # NOTE: timestamps
    create_time: any(),
    update_time: any()
  }

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
    |> foreign_key_constraint(:tournament_id)
  end
end

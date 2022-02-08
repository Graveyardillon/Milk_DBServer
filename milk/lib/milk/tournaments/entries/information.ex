defmodule Milk.Tournaments.Entries.Information do
  @moduledoc """
  エントリー情報
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Entry

  @type t :: %__MODULE__{
    entry_id: integer(),
    title: String.t(),
    field: String.t() | nil,
    # NOTE: timestamps
    create_time: any(),
    update_time: any()
  }

  schema "entry_information" do
    belongs_to :entry, Entry

    field :title, :string
    field :field, :string

    timestamps()
  end

  @doc false
  def changeset(information, attrs) do
    information
    |> cast(attrs, [:entry_id, :title, :field])
    |> validate_required([:entry_id, :title])
  end
end

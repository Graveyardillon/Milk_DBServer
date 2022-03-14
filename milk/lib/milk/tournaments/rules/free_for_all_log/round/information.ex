defmodule Milk.Tournaments.Rules.FreeForAllLog.Round.Information do
  @moduledoc """
  round infoのログ
  """
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Tournaments.Rules.FreeForAllLog.Round.Table

  schema "tournaments_rules_freeforalllog_round_information" do
    belongs_to :table, Table
    field :user_id, :integer

    timestamps()
  end

  @doc false
  def changeset(info, attrs) do
    info
    |> cast(attrs, [:table_id, :user_id])
    |> foreign_key_constraint(:table_id)
  end
end

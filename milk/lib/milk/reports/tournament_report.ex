defmodule Milk.Reports.TournamentReport do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Accounts.User
  alias Milk.Platforms.Platform

  schema "tournament_reports" do
    belongs_to :reporter, User
    belongs_to :master, User
    belongs_to :platform, Platform

    field :report_type, :integer
    field :capacity, :integer
    field :deadline, EctoDate
    field :description, :string
    field :event_date, EctoDate
    field :name, :string
    field :type, :integer
    field :url, :string
    field :thumbnail_path, :string
    field :count, :integer, default: 0
    field :game_name, :string
    field :start_recruiting, EctoDate

    timestamps()
  end

  @doc false
  def changeset(tournament_report, attrs) do
    tournament_report
    |> cast(attrs, [:report_type, :capacity, :deadline, :description, :event_date, :name, :type, :url, :thumbnail_path, :count, :game_name, :start_recruiting])
    |> validate_required([:report_type, :capacity, :deadline, :description, :event_date, :name, :type, :url, :thumbnail_path, :count, :game_name, :start_recruiting])
    |> foreign_key_constraint(:reporter_id)
    |> foreign_key_constraint(:master_id)
    |> foreign_key_constraint(:platform_id)
  end
end

defmodule Milk.Log.TeamMemberLog do
  @moduledoc """
  TeamMemberのログ
  """
  use Milk.Schema

  import Ecto.Changeset

  schema "team_member_log" do
    field :user_id, :integer
    field :team_id, :integer
    field :is_leader, :boolean
    field :is_invitation_confirmed, :boolean

    timestamps()
  end

  @doc false
  def changeset(team_member_log, attrs) do
    team_member_log
    |> cast(attrs, [:user_id, :team_id, :is_leader, :is_invitation_confirmed])
  end
end

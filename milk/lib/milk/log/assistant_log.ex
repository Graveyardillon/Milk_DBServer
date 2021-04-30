defmodule Milk.Log.AssistantLog do
  use Milk.Schema
  import Ecto.Changeset

  schema "assistants_log" do
    field :tournament_id, :integer
    field :user_id, :integer

    field :create_time, EctoDate
    field :update_time, EctoDate
  end

  @doc false
  def changeset(assistant_log, attrs) do
    assistant_log
    |> cast(attrs, [:tournament_id, :user_id, :create_time, :update_time])
    |> validate_required([:tournament_id, :user_id])
  end
end

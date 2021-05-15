defmodule Milk.Accounts.ActionHistory do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Accounts.User

  schema "action_histories" do
    field :user_id, :integer
    field :game_name, :string

    timestamps()
  end

  def changeset(action_history, attrs) do
    action_history
    |> cast(attrs, [:user_id, :game_name])
    |> validate_required([:user_id, :game_name])
  end
end

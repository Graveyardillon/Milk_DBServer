defmodule Milk.Accounts.ActionHistory do
  use Milk.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          user_id: integer(),
          game_name: String.t(),
          gain: integer(),
          # NOTE: timestamps
          create_time: any(),
          update_time: any()
        }

  schema "action_histories" do
    field :user_id, :integer
    field :game_name, :string
    field :gain, :integer

    timestamps()
  end

  def changeset(action_history, attrs) do
    action_history
    |> cast(attrs, [:user_id, :game_name, :gain])
    |> validate_required([:user_id, :game_name, :gain])
  end
end

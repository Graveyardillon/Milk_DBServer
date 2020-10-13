defmodule Milk.Schema do

  defmacro __using__(opts) do
    _opts = Keyword.merge([default_sort: :inserted_at], opts)

    quote do
      use Ecto.Schema
      alias Milk.EctoDate
      @timestamps_opts [type: EctoDate, inserted_at: :create_time, updated_at: :update_time]

      import Ecto
      import Ecto.Changeset
      import Ecto.Query, only: [from: 1, from: 2]

      alias Milk.Repo
      
    end
  end
end
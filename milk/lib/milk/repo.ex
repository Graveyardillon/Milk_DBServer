defmodule Milk.Repo do
  use Ecto.Repo,
    otp_app: :milk,
    adapter: Ecto.Adapters.Postgres
end

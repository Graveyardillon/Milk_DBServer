use Mix.Config

# Configure your database
config :milk, Milk.Repo,
  username: "postgres",
  password: "postgres",
  database: "milk_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :milk, MilkWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

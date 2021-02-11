use Mix.Config

# Configure your database
config :milk, Milk.Repo,
  username: "postgres",
  password: "postgres",
  database: "milk_test",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :milk, MilkWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :milk, :redix_host, "localhost"
config :milk, :redix_port, 6379
config :milk, Milk.Repo, migration_timestamps: [type: :timestamptz, inserted_at: :create_time, updated_at: :update_time]
config :milk, :environment, :test

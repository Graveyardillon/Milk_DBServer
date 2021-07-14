use Mix.Config

# Configure your database
config :milk, Milk.Repo,
  username: System.get_env("MILK_TEST_USERNAME") || "postgres",
  password: System.get_env("MILK_TEST_PASSWORD") || "postgres",
  database: System.get_env("MILK_TEST_DATABASE") || "milk_test",
  hostname: System.get_env("MILK_TEST_HOSTNAME") || "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  pool: Ecto.Adapters.SQL.Sandbox,
  ownership_timeout: :infinity,
  timeout: :infinity

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :milk, MilkWeb.Endpoint,
  http: [port: 4002],
  server: false

config :pigeon, :apns,
  apns_default: %{
    key: "priv/cert/AuthKey_MHN824H499.p8",
    key_identifier: "MHN824H499",
    team_id: "6ZMC8WKZZQ",
    mode: :dev
  }

config :milk, Milk.Mailer, adapter: Bamboo.TestAdapter

# Print only warnings and errors during test
config :logger, level: :warn

config :milk, :redix_host, System.get_env("MILK_TEST_REDISHOST") || "localhost"
config :milk, :redix_port, System.get_env("MILK_TEST_REDISPORT") || 6379

config :milk, Milk.Repo,
  migration_timestamps: [type: :timestamptz, inserted_at: :create_time, updated_at: :update_time]

config :milk, :environment, :test

config :milk, Oban, queues: false, plugins: false

use Mix.Config

# Configure your database
config :milk, Milk.Repo,
  username: "postgres",
  password: "postgres",
  database: "milk_dev",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with webpack to recompile .js and .css sources.
config :milk, MilkWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# Mix task:
#
#     mix phx.gen.cert
#
# Note that this task requires Erlang/OTP 20 or later.
# Run `mix help phx.gen.cert` for more information.
#
# The `http:` config above can be replaced with:
#
#     https: [
#       port: 4001,
#       cipher_suite: :strong,
#       keyfile: "priv/cert/selfsigned_key.pem",
#       certfile: "priv/cert/selfsigned.pem"
#     ],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Watch static and templates for browser reloading.
config :milk, MilkWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/milk_web/{live,views}/.*(ex)$",
      ~r"lib/milk_web/templates/.*(eex)$"
    ]
  ]

config :pigeon, :apns,
  apns_default: %{
    key: "priv/cert/AuthKey_MHN824H499.p8",
    key_identifier: "MHN824H499",
    team_id: "6ZMC8WKZZQ",
    mode: :dev
  }

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

config :milk, Milk.Repo, migration_timestamps: [type: :timestamptz, inserted_at: :create_time, updated_at: :update_time]

config :milk, :redix_host, "localhost"
config :milk, :redix_port, 6379
config :milk, :environment, :dev

config :milk, :domain, "http://localhost:3000"

config :milk, :discord_server, "http://localhost:8080"

config :dfa, :redis_host, "localhost"
config :dfa, :redis_port, 6379

# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :milk, ecto_repos: [Milk.Repo]

# Configures the endpoint
config :milk, MilkWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "EBeu358sy8Bi+OLxOAee44nMrRCj/iwRKq5NUls46hBMwnqVhNOhl7qcw0d1REjZ",
  render_errors: [view: MilkWeb.ErrorView, accepts: ~w(html json)]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

config :milk, Milk.UserManager.Guardian,
  issuer: "milk",
  secret_key: "ucwM9beYUEgWdkHoZ5kXflOMW8wZSEVwheR3PuUVROQrl3uymZL/qtRbHs+V3BN4",
  serializer: Milk.UserManager.GuardianSerializer,
  ttl: {24, :hour}

  config :milk, Milk.UserManager.Pipeline,
  module: Milk.UserManager.Guardian,
  error_handler: Milk.UserManager.ErrorHandler


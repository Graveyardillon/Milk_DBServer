# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

# database_url =
#  System.get_env("DATABASE_URL") ||
#    raise """
#    environment variable DATABASE_URL is missing.
#    For example: ecto://USER:PASS@HOST/DATABASE
#    """

config :milk, Milk.Repo,
  username: "postgres",
  password: "postgres",
  database: "milkdb",
  socket_dir: "/tmp/cloudsql/" <> System.get_env("CLOUD_SQL_HOST"),
  pool_size: 10

# secret_key_base =
#  System.get_env("SECRET_KEY_BASE") ||
#    raise """
#    environment variable SECRET_KEY_BASE is missing.
#    You can generate one by calling: mix phx.gen.secret
#    """

config :milk, MilkWeb.Endpoint,
  load_from_system_env: true,
  http: [port: {:system, "PORT"}],
  check_origin: false,
  server: true,
  root: ".",
  secret_key_base: "LqoR7+lZoQ0d7SFXzx2GJhzn8QrhoOn2tM43fL6i+2S0d//IjQ4+y+gOcSxsK+2f"

config :pigeon, :apns,
  apns_default: %{
    key: "lib/milk-#{Application.spec(:milk, :vsn)}/priv/cert/AuthKey_MHN824H499.p8",
    key_identifier: "MHN824H499",
    team_id: "6ZMC8WKZZQ",
    mode: :prod
  }

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :milk, MilkWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.

config :milk, :redix_host, "10.231.150.131"
config :milk, :redix_port, 6379
config :milk, :environment, :prod

config :milk, :domain, "https://e-players-web.web.app"

config :milk, :discord_server, "https://discordserver-dot-e-players6814.an.r.appspot.com"
config :dfa, :redis_host, "10.231.150.131"
config :dfa, :redis_port, 6379

# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

#database_url =
#  System.get_env("DATABASE_URL") ||
#    raise """
#    environment variable DATABASE_URL is missing.
#    For example: ecto://USER:PASS@HOST/DATABASE
#    """

config :milk, Milk.Repo,
  username: "postgres",
  password: "1il5eEpK8rTc0ba1N",
  database: "milk",
  socket_dir: "/tmp/cloudsql/crack-producer-298904:asia-northeast1:milkdb",
  pool_size: 10

#secret_key_base =
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

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :milk, MilkWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.

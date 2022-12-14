# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :live_map,
  ecto_repos: [LiveMap.Repo]

# config :elixir_auth_google,
#   google_client_id: System.get_env("GOOGLE_CLIENT_ID"),
#   google_client_secret: System.get_env("GOOGLE_CLIENT_SECRET"),
#   google_scope: "profile email"

# config :elixir_auth_github,
#   github_client_id: System.get_env("GITHUB_CLIENT_ID"),
#   github_client_secret: System.get_env("GITHUB_CLIENT_SECRET"),
#   github_scope: "public_profile"

config :live_map,
  app_id: System.get_env("FACEBOOK_APP_ID"),
  app_secret: System.get_env("FACEBOOK_APP_SECRET"),
  app_state: System.get_env("FACEBOOK_STATE")

config :geo_postgis,
  json_library: Jason

# Configures the endpoint
config :live_map, LiveMapWeb.Endpoint,
  # url: [host: "myapp.localhost"],
  render_errors: [view: LiveMapWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: LiveMap.PubSub,
  live_view: [signing_salt: "ez1lDCj3"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :live_map, LiveMapMail.Mailer, adapter: Swoosh.Adapters.Local

# sets default time range for query
config :live_map, default_days: 30

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# --splitting
# --format=esm

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.29",
  default: [
    args: ~w(
      js/app.js
      --bundle
      --target=es2020
      --sourcemap
      --loader:.png=dataurl
      --outdir=../priv/static/assets
      --external:/fonts/*
      --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "3.1.8",
  default: [
    args: ~w(
      --config=tailwind.config.cjs
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

# config :elixir_auth_facebook,
#   app_id: System.get_env("FACEBOOK_APP_ID"),
#   app_secret: System.get_env("FACEBOOK_APP_SECRET"),
#   app_state: System.get_env("FACEBOOK_STATE"),
#   https: true

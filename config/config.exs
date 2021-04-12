# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :choracle,
  ecto_repos: [Choracle.Repo]

# Configures the endpoint
config :choracle, ChoracleWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "m8pc3fxb8eltcV/mGtL0v4L4S51IX4nZ4Qx94tk8CeLXo4D0NRprpv2XMPJUwbHJ",
  render_errors: [view: ChoracleWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Choracle.PubSub,
  live_view: [signing_salt: "m9AcrCRY"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

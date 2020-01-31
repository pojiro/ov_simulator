# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :ov_simulator, OvSimulatorWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "B2e8J08zDvsNbbcTKPLQUlylZs3xeTzNTfGDr1nszQjilC7oRMkDA3hz2baBisnE",
  render_errors: [view: OvSimulatorWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: OvSimulator.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [
    signing_salt: "u6j0rAlCgzcfShmK2WS8S7i18VNb8BlD"
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :git_hooks,
  verbose: true,
  hooks: [
    pre_commit: [
      tasks: [
        "mix format",
        "mix test"
      ]
    ],
    pre_push: [
      tasks: []
    ]
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

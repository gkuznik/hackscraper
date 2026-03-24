# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :hackscraper,
  ecto_repos: [HackScraper.Repo],
  generators: [timestamp_type: :utc_datetime]

one_day = 24 * 60 * 60

config :hackscraper, Oban,
  engine: Oban.Engines.Basic,
  queues: [default: 5, scraper: 10, emails: 10],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 365 * one_day, interval: one_day * 1000},
    {Oban.Plugins.Cron,
     crontab: [
       {"@weekly", HackScraper.Worker.Scheduler}
     ]}
  ],
  repo: HackScraper.Repo

config :flop, repo: HackScraper.Repo

config :pythonx, :uv_init,
  pyproject_toml: """
  [project]
  name = "scrapers"
  version = "0.0.1"
  requires-python = ">=3.10"
  dependencies = [
    "beautifulsoup4>=4.14",
    "trafilatura>=2.0",
    "nextjs-hydration-parser>=0.4.0"
  ]
  """

# Configures the endpoint
config :hackscraper, HackScraperWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: HackScraperWeb.ErrorHTML, json: HackScraperWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: HackScraper.PubSub,
  live_view: [signing_salt: "XtRhmVEa"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :hackscraper, HackScraper.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  hackscraper: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  hackscraper: [
    args: ~w(
      --config=tailwind.config.js
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

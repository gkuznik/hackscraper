defmodule HackScraper.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      HackScraperWeb.Telemetry,
      HackScraper.Repo,
      {DNSCluster, query: Application.get_env(:hackscraper, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: HackScraper.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: HackScraper.Finch},
      # Start a worker by calling: HackScraper.Worker.start_link(arg)
      # {HackScraper.Worker, arg},
      # Start to serve requests, typically the last entry
      HackScraperWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HackScraper.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HackScraperWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

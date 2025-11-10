defmodule Hackscraper.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      HackscraperWeb.Telemetry,
      Hackscraper.Repo,
      {DNSCluster, query: Application.get_env(:hackscraper, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Hackscraper.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Hackscraper.Finch},
      # Start a worker by calling: Hackscraper.Worker.start_link(arg)
      # {Hackscraper.Worker, arg},
      # Start to serve requests, typically the last entry
      HackscraperWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Hackscraper.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HackscraperWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

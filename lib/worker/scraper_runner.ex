defmodule HackScraper.Worker.ScraperRunner do
  use Oban.Worker, queue: :scraper, priority: 2, max_attempts: 3

  import HackScraper.Worker.Common,
    only: [upsert_suggestions: 1, upsert_hackathons: 1, worker_module: 1]

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"worker_name" => worker_name} = args}) do
    module = worker_module(worker_name)
    Logger.info("Running scraper runner for #{worker_name}...")

    case module.scrape(args) do
      {:suggestions, suggestions} ->
        Logger.info("Found #{length(suggestions)} suggestions for #{worker_name}")
        num = upsert_suggestions(suggestions)
        Logger.info("Created/updated #{num} suggestions")
        :ok

      {:hackathons, hackathons} ->
        Logger.info("Found #{length(hackathons)} hackathons for #{worker_name}")
        num = upsert_hackathons(hackathons)
        Logger.info("Created/updated #{num} hackathons")
        :ok

      {:jobs, jobs} ->
        Logger.info("Queuing #{length(jobs)} sub-jobs for #{worker_name}")

        Enum.reduce(jobs, Ecto.Multi.new(), fn job, multi ->
          name = "job-#{System.unique_integer([:positive])}"
          Oban.insert(multi, name, job)
        end)
        |> HackScraper.Repo.transaction()

        :ok
    end
  end
end

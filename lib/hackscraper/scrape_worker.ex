defmodule HackScraper.InspectWorker do
  use Oban.Worker, queue: :scraper, max_attempts: 3

  @impl Oban.Worker
  def perform(job) do
    url = job.args["url"]
    IO.inspect("Running Job", url: url)
    :ok
  end
end

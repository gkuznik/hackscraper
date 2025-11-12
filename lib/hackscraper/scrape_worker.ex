defmodule HackScraper.InspectWorker do
  use Oban.Worker

  @impl Oban.Worker
  def perform(job) do
    url = job.args["url"]
    IO.inspect("Running Job", url: url)
    :ok
  end
end

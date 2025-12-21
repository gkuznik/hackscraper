defmodule HackScraper.Worker.Dummy do
  use Oban.Worker

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"url" => url}}) do
    Logger.info("Running dummy scraper: #{url}...")

    Process.sleep(1000)

    Logger.info("Done sleeping")
  end
end

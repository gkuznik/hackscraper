defmodule HackScraper.Scraper.Direct do
  use Oban.Worker

  import HackScraper.Scraper.Common

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"url" => url}}) do
    Logger.info("Running direct scraper", url: url)

    _data = get!(url)

    suggestions = []

    # TODOs

    upsert_suggestions(suggestions)

    Logger.info("Created #{length(suggestions)} suggestions")
  end
end

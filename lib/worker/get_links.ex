defmodule HackScraper.Worker.GetLinks do
  import HackScraper.Worker.Common
  require Logger

  def scrape(%{"url" => url}) do
    Logger.info("Running links scraper: #{url}...")
    body = get!(url).body

    links =
      body
      |> Floki.parse_document!()
      |> Floki.find("a[href]")
      |> Floki.attribute("href")
      |> Enum.filter(&String.contains?(String.downcase(&1), "hackathon"))
      |> Enum.map(&(URI.merge(url, &1) |> URI.to_string()))
      |> MapSet.new()

    Logger.info("Found #{MapSet.size(links)} hackathon links")

    # TODO filter against already known links
    # then schedule workers
    {:suggestions, []}
  end
end

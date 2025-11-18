defmodule HackScraper.Scraper.Devpost do
  use HackScraper.Scraper

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{} = _job) do
    Logger.info("Running Devpost scraper")

    api_url =
      "https://devpost.com/api/hackathons?open_to[]=public&search=munich&status[]=upcoming&status[]=open"

    data = get!(api_url).body["hackathons"]

    Logger.info("Found #{length(data)} hackathons")

    suggestions =
      for hack <- data do
        %{
          url: hack["url"],
          image: "https:" <> hack["thumbnail_url"],
          name: hack["title"],
          description: Enum.map(hack["themes"], & &1["name"]) |> Enum.join(", "),
          date: hack["submission_period_dates"],
          location: hack["displayed_location"]["location"]
        }
      end

    upsert_suggestions(suggestions)

    Logger.info("Created/updated #{length(suggestions)} suggestions")
  end
end

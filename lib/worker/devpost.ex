defmodule HackScraper.Worker.Devpost do
  use Oban.Worker

  import HackScraper.Worker.Common

  require Logger

  @api_url "https://devpost.com/api/hackathons?open_to[]=public&search=munich&status[]=upcoming&status[]=open"

  @impl Oban.Worker
  def perform(%Oban.Job{} = _job) do
    Logger.info("Running Devpost scraper...")

    data = get!(@api_url).body["hackathons"]
    Logger.info("Found #{length(data)} hackathons")

    suggestions =
      for hack <- data do
        %{
          url: hack["url"],
          image: "https:" <> hack["thumbnail_url"],
          name: hack["title"],
          description: Enum.map(hack["themes"], & &1["name"]) |> Enum.join(", "),
          date_hint: hack["submission_period_dates"],
          location: hack["displayed_location"]["location"]
        }
      end

    num = upsert_suggestions(suggestions)
    Logger.info("Created/updated #{num} suggestions")
  end
end

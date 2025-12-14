defmodule HackScraper.Worker.LabLab do
  use Oban.Worker

  import HackScraper.Worker.Common

  require Logger

  @api_url "https://lablab.ai/_next/data/amtvrhqGU_ZE8AWyCNT5E/event.json"

  @impl Oban.Worker
  def perform(%Oban.Job{} = _job) do
    Logger.info("Running Devpost scraper...")

    data = get!(@api_url).body["pageProps"]["sortedEvents"]
    Logger.info("Found #{length(data)} hackathons")

    hackathons =
      for hack <- data do
        %{
          url: "https://lablab.ai/event/#{hack["slug"]}",
          image: hack["imageLink"],
          name: hack["name"],
          description: hack["description"],
          start_date: parse_date(hack["startAt"]),
          end_date: parse_date(hack["endAt"]),
          location: "Online"
        }
      end

    num = upsert_hackathons(hackathons)
    Logger.info("Created/updated #{num} hackathons")
  end
end

defmodule HackScraper.Worker.N3xtcoder do
  use Oban.Worker

  import HackScraper.Worker.Common

  require Logger

  @api_url "https://n3xtcoder.org/api/event-cards?offset=0&sort=desc&pageSize=6&lang=en"

  @impl Oban.Worker
  def perform(%Oban.Job{} = _job) do
    Logger.info("Running N3xtcoder scraper...")

    cards = get!(@api_url).body["data"]["cards"]

    hackathons =
      for card <- cards, card["typeOfEvent"] == "hackathon" do
        time = card["timeFrame"]
        {name, description} = split_title(card["title"])

        %{
          url: URI.merge("https://n3xtcoder.org/", card["slug"]) |> to_string(),
          image: "/images/n3xtcoder.png",
          name: name,
          description: description,
          start_date: parse_date(time["starttime"]),
          end_date: parse_date(time["endtime"])
        }
      end

    Logger.info("Found #{length(hackathons)}/#{length(cards)} hackathons")
    num = upsert_hackathons(hackathons)
    Logger.info("Created/updated #{num} hackathons")
  end
end

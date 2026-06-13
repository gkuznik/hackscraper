defmodule HackScraper.Worker.N3xtcoder do
  import HackScraper.Worker.Common
  require Logger

  def scrape(%{"url" => url}) do
    Logger.info("Running N3xtcoder scraper...")

    cards = get!(url).body["data"]["cards"]

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
    {:hackathons, hackathons}
  end
end

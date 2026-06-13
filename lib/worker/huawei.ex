defmodule HackScraper.Worker.Huawei do
  import HackScraper.Worker.Common
  require Logger

  def scrape(%{"url" => url}) do
    Logger.info("Running Huawei scraper...")

    data = get!(url).body["data"]
    Logger.info("Found #{length(data)} hackathons")

    hackathons =
      for item <- data do
        hack = item["attributes"]

        %{
          url: "https://huawei.agorize.com/challenges/#{hack["slug"]}",
          image: hack["board_image_url"],
          name: hack["name"],
          description: hack["awards_catchline"] <> "\n\n" <> hack["summary"],
          start_date: parse_date(hack["start_at"]),
          end_date: parse_date(hack["create_or_join_team_allowed_until"])
        }
      end

    {:hackathons, hackathons}
  end
end

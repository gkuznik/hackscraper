defmodule HackScraper.Worker.Huawei do
  use Oban.Worker

  import HackScraper.Worker.Common

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"url" => url}}) do
    Logger.info("Running Huawei scraper...")

    hackathons = get!(url).body["data"]
    Logger.info("Found #{length(hackathons)} hackathons")

    hackathons =
      for item <- hackathons do
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

    num = upsert_hackathons(hackathons)
    Logger.info("Created/updated #{num} hackathons")
  end
end

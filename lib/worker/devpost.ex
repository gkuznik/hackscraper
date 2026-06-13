defmodule HackScraper.Worker.Devpost do
  import HackScraper.Worker.Common
  require Logger

  def scrape(%{"url" => url}) do
    data = get!(url).body["hackathons"]
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

    {:suggestions, suggestions}
  end
end

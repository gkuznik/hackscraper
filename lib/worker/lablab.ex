defmodule HackScraper.Worker.LabLab do
  import HackScraper.Worker.Common
  require Logger

  def scrape(%{"url" => url}) do
    Logger.info("Running Lablab.ai scraper...")

    html = get!(url).body

    {result, _globals} =
      Pythonx.eval(
        """
        # Elixir strings are bytes
        html = html.decode("utf-8")

        from nextjs_hydration_parser import NextJSHydrationDataExtractor

        extractor = NextJSHydrationDataExtractor()
        chunks = extractor.parse(html)
        results = extractor.find_data_by_pattern(chunks, 'events')
        [v for v in results if v['key'] in ('events', 'sortedEvents')][0]['value']
        """,
        %{"html" => html}
      )

    data = Pythonx.decode(result)
    Logger.info("Found #{length(data)} hackathons")

    hackathons =
      for hack <- data, hack["active"], is_binary(hack["startAt"]), is_binary(hack["endAt"]) do
        %{
          url: "https://lablab.ai/event/#{hack["slug"]}",
          image: hack["imageLink"],
          name: hack["name"],
          description: hack["description"],
          start_date: parse_date(String.trim(hack["startAt"], "$D")),
          end_date: parse_date(String.trim(hack["endAt"], "$D")),
          location: "Online"
        }
      end

    {:hackathons, hackathons}
  end
end

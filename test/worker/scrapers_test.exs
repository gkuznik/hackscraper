defmodule HackScraper.Worker.ScrapersTest do
  use ExUnit.Case, async: true
  import Exposure

  # List of scrapers to test.
  # The list includes the worker module, the target URL to mock,
  # and the input mock file path.
  @scrapers [
    %{
      name: "Devpost",
      module: HackScraper.Worker.Devpost,
      url:
        "https://devpost.com/api/hackathons?open_to[]=public&search=munich&status[]=upcoming&status[]=open",
      input: "test/worker/input/devpost.com.json"
    },
    %{
      name: "Huawei",
      module: HackScraper.Worker.Huawei,
      url: "https://huawei.agorize.com/api/v2/challenges",
      input: "test/worker/input/huawei.agorize.com.json"
    },
    %{
      name: "N3xtcoder",
      module: HackScraper.Worker.N3xtcoder,
      url: "https://n3xtcoder.org/api/event-cards?offset=0&sort=desc&pageSize=6&lang=en",
      input: "test/worker/input/n3xtcoder.org.json"
    },
    %{
      name: "Taikai",
      module: HackScraper.Worker.Taikai,
      url: "https://api.taikai.network/api/graphql",
      input: "test/worker/input/api.taikai.network.json"
    },
    %{
      name: "TUM Think Tank",
      module: HackScraper.Worker.TUMThinkTank,
      url: "https://tumthinktank.de/events/",
      input: "test/worker/input/tumthinktank.de.html"
    },
    %{
      name: "Unternehmertum",
      module: HackScraper.Worker.Unternehmertum,
      url: "https://www.unternehmertum.de/events?filter%5B%5D=9511",
      input: "test/worker/input/www.unternehmertum.de.html"
    }
  ]

  setup do
    # Configure Req to use a single shared stub globally to avoid overrides
    Req.default_options(plug: {Req.Test, HackScraper.Worker.ScrapersTest})
    :ok
  end

  # Dynamically generate a test for each scraper
  for scraper <- @scrapers do
    @scraper scraper

    test_snapshot "scrapes #{@scraper.name}" do
      module = @scraper.module
      url = @scraper.url
      input_path = @scraper.input

      # Load input data
      input_body = File.read!(input_path)

      input_data =
        if String.ends_with?(input_path, ".json") do
          Jason.decode!(input_body)
        else
          input_body
        end

      # Stub the shared Req.Test module to return the input data
      Req.Test.stub(HackScraper.Worker.ScrapersTest, fn conn ->
        if is_binary(input_data) do
          Req.Test.html(conn, input_data)
        else
          Req.Test.json(conn, input_data)
        end
      end)

      # Call the scraper's scrape/1 function directly
      {type, items} = module.scrape(%{"url" => url})

      # Sort the items by URL for stable snapshot comparison
      sorted_items = Enum.sort_by(items, & &1.url)

      # Return the normalized tuple for the snapshot assertion
      {type, sorted_items}
    end
  end
end

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
    },
    %{
      name: "Luma",
      module: HackScraper.Worker.Luma,
      url:
        "https://api2.luma.com/discover/get-paginated-events?latitude=48.13743&longitude=11.57549&pagination_limit=30&slug=tech",
      input: "test/worker/input/luma/luma.json"
    },
    %{
      name: "Luma AddInfo",
      module: HackScraper.Worker.Luma.AddInfo,
      url: "https://luma.com/edth-2026-munich",
      input: "test/worker/input/luma/edth-2026-munich.html",
      args: %{
        "event" => %{
          "url" => "https://luma.com/edth-2026-munich",
          "name" => "European Defense Tech Hackathon – Munich",
          "start_date" => "2026-02-12T11:00:00.000Z",
          "end_date" => "2026-02-15T17:00:00.000Z",
          "series_id" => nil
        }
      }
    },
    %{
      name: "TUM Venture Labs",
      module: HackScraper.Worker.TUMVentureLabs,
      url:
        "https://www.tum-venture-labs.de/index.php?p=actions/sprig-core/components/render&eventFormats[]=66989&reset=false&search=&sprig:siteId=9a1761719fed643d2a9161f9bfa109521c7487343e041b2d3541f6f497b907ed1&sprig:id=18f5b0bbf1163c3ee576f32b2b84820f55e7f2099ee44df628295be00ca478d4s-events-list&sprig:component=7b3a1f07361ad5a76557bad89bff243735691e7103956a9201f2c2959b531556&sprig:template=49f84ea3b95926b92ef6f0545f1b9613962135886d4703c8e69d52dcaacc4088events/_event-list",
      input: "test/worker/input/tum venture labs/tum-venture-labs.html"
    },
    %{
      name: "TUM Venture Labs AddInfo",
      module: HackScraper.Worker.TUMVentureLabs.AddInfo,
      url: "https://www.tum-venture-labs.de/events/aec-hackathon-munich-edition/",
      input: "test/worker/input/tum venture labs/aec-hackathon-munich-edition.html",
      args: %{
        "event" => %{
          "url" => "https://www.tum-venture-labs.de/events/aec-hackathon-munich-edition/",
          "name" => "AEC Hackathon - Munich Edition",
          "date_hint" => "Jun 20 - 22, 2025",
          "series_id" => nil
        }
      }
    },
    %{
      name: "LabLab",
      module: HackScraper.Worker.LabLab,
      url: "https://lablab.ai/ai-hackathons",
      input: "test/worker/input/lablab.ai.html"
    },
    %{
      name: "Direct HackTUM",
      module: HackScraper.Worker.Direct,
      url: "https://hack.tum.de",
      input: "test/worker/input/hack.tum.de.html"
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
      args = @scraper[:args] || %{"url" => url}
      {type, items} = module.scrape(args)

      # Normalize and sort the items for stable snapshot comparison
      normalized_items =
        items
        |> Enum.map(fn
          %Ecto.Changeset{} = changeset ->
            changeset.changes |> Map.delete(:scheduled_at)

          item ->
            item
        end)
        |> Enum.sort_by(fn item ->
          cond do
            is_map(item) and is_map(item[:args]) and is_map(item[:args]["event"]) ->
              item[:args]["event"]["url"]

            is_map(item) and is_map(item[:args]) ->
              item[:args]["url"]

            is_map(item) ->
              item[:url] || item["url"]

            true ->
              nil
          end
        end)

      # Return the normalized tuple for the snapshot assertion
      {type, normalized_items}
    end
  end
end

defmodule HackScraper.Worker.TUMVentureLabs do
  import HackScraper.Worker.Common
  require Logger

  def scrape(%{"url" => url} = args) do
    Logger.info("Running TUMVentureLabs scraper...")

    html = get!(url).body
    cards = html |> Floki.parse_document!() |> Floki.find(".grid .sm\\:col-6")
    Logger.info("Found #{length(cards)} events")

    series_id = args["series_id"]

    jobs =
      for {card, index} <- Enum.with_index(cards) do
        link = Floki.find(card, "a")
        url = Floki.attribute(link, "href") |> List.first()
        name = Floki.text(link) |> String.trim()

        date =
          card
          |> Floki.find("p.fw-bold")
          |> Floki.text()
          |> String.trim()

        event = %{url: url, name: name, date_hint: date, series_id: series_id}

        %{
          "worker_name" => "TUMVentureLabs.AddInfo",
          "event" => event
        }
        |> HackScraper.Worker.ScraperRunner.new(
          schedule_in: index * 180,
          priority: 3,
          max_attempts: 2,
          unique: [
            period: {60, :days},
            states: :all,
            fields: [:queue, :args],
            keys: [:event]
          ]
        )
      end

    Logger.info("Queued AddInfo jobs")
    {:jobs, jobs}
  end
end

defmodule HackScraper.Worker.TUMVentureLabs.AddInfo do
  import HackScraper.Worker.Common
  require Logger

  def scrape(%{"event" => %{"url" => url} = event}) do
    Logger.info("Running TUMVentureLabs AddInfo scraper: #{url}...")

    html = get!(url).body |> Floki.parse_document!()

    description =
      html
      |> Floki.find("div.prose")
      |> List.first()
      |> Floki.text(sep: "\n")
      |> String.trim()

    location =
      html
      |> Floki.find(".facts-dl-item")
      |> Enum.find_value(fn item ->
        term = Floki.find(item, ".facts-dl-term") |> Floki.text() |> String.trim()

        if term == "Where" do
          Floki.find(item, ".facts-dl-definition") |> Floki.text() |> String.trim()
        end
      end)

    actual_url =
      html
      |> Floki.find(".header-split-content-footer a")
      |> Floki.attribute("href")
      |> List.first()

    event_atoms =
      for {key, val} <- event,
          into: %{},
          do: {String.to_existing_atom(key), val}

    map =
      event_atoms
      |> Map.put(:description, description)
      |> Map.put(:location, location)
      |> Map.put(:image, extract_best_image(html))

    suggestion = if actual_url, do: Map.put(map, :url, actual_url), else: map

    {:suggestions, [suggestion]}
  end

  defp extract_best_image(html) do
    img = Floki.find(html, ".header-split-image img")

    with srcset when srcset != [] <- Floki.attribute(img, "srcset"),
         srcset_str when is_binary(srcset_str) <- List.first(srcset) do
      srcset_str
      |> String.split(",")
      |> Enum.map(fn entry ->
        [url, width] = entry |> String.trim() |> String.split(" ", parts: 2)
        {String.to_integer(String.trim_trailing(width, "w")), url}
      end)
      |> Enum.max_by(&elem(&1, 0))
      |> elem(1)
    else
      _ -> Floki.attribute(img, "src") |> List.first()
    end
  end
end

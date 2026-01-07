defmodule HackScraper.Worker.TUMVentureLabs do
  use Oban.Worker

  import HackScraper.Worker.Common

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"url" => url}}) do
    Logger.info("Running TUMVentureLabs scraper...")

    html = get!(url).body
    cards = html |> Floki.parse_document!() |> Floki.find(".grid .sm\\:col-6")

    events =
      for card <- cards do
        link = Floki.find(card, "a")
        url = Floki.attribute(link, "href") |> List.first()
        name = Floki.text(link) |> String.trim()

        date =
          card
          |> Floki.find("p.fw-bold")
          |> Floki.text()
          |> String.trim()

        %{url: url, name: name, date_hint: date}
      end

    Logger.info("Found #{length(events)} events")

    events
    |> Enum.with_index()
    |> Enum.reduce(Ecto.Multi.new(), fn {event, index}, multi ->
      job =
        HackScraper.Worker.TUMVentureLabs.AddInfo.new(%{event: event}, schedule_in: index * 180)

      Oban.insert(multi, "addinfo-#{index}", job)
    end)
    |> HackScraper.Repo.transaction()

    Logger.info("Queued AddInfo jobs")
  end
end

defmodule HackScraper.Worker.TUMVentureLabs.AddInfo do
  use Oban.Worker,
    priority: 3,
    unique: [period: {60, :days}, states: :all, fields: [:queue, :args], keys: [:url]],
    max_attempts: 2

  require Logger
  import HackScraper.Worker.Common

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"event" => event}}) do
    event = for {key, val} <- event, into: %{}, do: {String.to_existing_atom(key), val}
    Logger.info("Running TUMVentureLabs AddInfo scraper: #{event.url}...")

    html = get!(event.url).body |> Floki.parse_document!()

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

    map =
      event
      |> Map.put(:description, description)
      |> Map.put(:location, location)
      |> Map.put(:image, extract_best_image(html))

    suggestion = if actual_url, do: Map.put(map, :url, actual_url), else: map

    num = upsert_suggestions([suggestion])
    Logger.info("Created/updated #{num} suggestion")
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

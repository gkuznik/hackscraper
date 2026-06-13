defmodule HackScraper.Worker.TUMThinkTank do
  import HackScraper.Worker.Common
  require Logger

  def scrape(%{"url" => url}) do
    Logger.info("Running TUM Think Tank scraper...")

    html = get!(url).body
    document = Floki.parse_document!(html)

    events = Floki.find(document, "article.teaser.basic-teaser--event")

    suggestions =
      for event <- events, is_hackathon?(event) do
        # 1. URL
        event_url =
          event
          |> Floki.find("a.teaser__link")
          |> Floki.attribute("href")
          |> List.first()
          |> then(&URI.merge(url, &1))
          |> URI.to_string()

        # 2. Name
        name =
          event
          |> Floki.find("h3.title")
          |> Floki.text()
          |> String.trim()

        # 3. Description
        description =
          event
          |> Floki.find("p.desc")
          |> Floki.text()
          |> String.trim()

        # 4. Image
        img = Floki.find(event, ".teaser__pic img")

        image =
          (Floki.attribute(img, "data-src") ++ Floki.attribute(img, "src")) |> List.first()

        # 5. Location and Date Hint
        meta_node = Floki.find(event, ".meta") |> List.first()
        {location, date_hint} = parse_meta(meta_node)

        %{
          url: event_url,
          name: name,
          description: description,
          image: image,
          location: location,
          date_hint: date_hint
        }
      end

    Logger.info("Found #{length(suggestions)} hackathon suggestions")
    {:suggestions, suggestions}
  end

  defp is_hackathon?(event) do
    event_types =
      case Floki.attribute(event, "data-filter-item") |> List.first() do
        nil ->
          []

        json_str ->
          case Jason.decode(json_str) do
            {:ok, %{"eventType" => types}} -> types
            _ -> []
          end
      end

    topline =
      event
      |> Floki.find(".topline")
      |> Floki.text()
      |> String.trim()
      |> String.downcase()

    "hackathon" in event_types or topline == "hackathon"
  end

  defp parse_meta(nil), do: {nil, nil}

  defp parse_meta({_, _, children}) do
    text_parts =
      Enum.map(children, fn
        {"br", _, _} -> "\n"
        child -> Floki.text(child)
      end)
      |> Enum.join("")
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    case text_parts do
      [location, date_hint] -> {location, date_hint}
      [single] -> {nil, single}
      _ -> {nil, nil}
    end
  end

  defp parse_meta(_), do: {nil, nil}
end

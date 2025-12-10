defmodule HackScraper.Worker.TUMVentureLabs do
  use Oban.Worker

  import HackScraper.Worker.Common

  require Logger

  @url "https://www.tum-venture-labs.de/index.php?p=actions/sprig-core/components/render&eventFormats[]=66989&reset=false&search=&sprig:siteId=9a1761719fed643d2a9161f9bfa109521c7487343e041b2d3541f6f497b907ed1&sprig:id=18f5b0bbf1163c3ee576f32b2b84820f55e7f2099ee44df628295be00ca478d4s-events-list&sprig:component=7b3a1f07361ad5a76557bad89bff243735691e7103956a9201f2c2959b531556&sprig:template=49f84ea3b95926b92ef6f0545f1b9613962135886d4703c8e69d52dcaacc4088events/_event-list"

  @impl Oban.Worker
  def perform(%Oban.Job{} = _job) do
    Logger.info("Running TUMVentureLabs scraper...")

    html = get!(@url).body
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

        %{creator_id: user_id(), url: url, name: name, date_hint: date}
      end

    Logger.info("Found #{length(events)} events")

    suggestions = Enum.map(events, &extra_info/1)

    num = upsert_suggestions(suggestions)
    Logger.info("Created #{num} suggestion")
  end

  defp extra_info(%{url: url} = event) do
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

    url =
      html
      |> Floki.find(".header-split-content-footer a")
      |> Floki.attribute("href")
      |> List.first()

    map =
      event
      |> Map.put(:description, description)
      |> Map.put(:location, location)
      |> Map.put(:image, extract_best_image(html))

    if url, do: Map.put(map, :url, url), else: map
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

defmodule HackScraper.Worker.Luma do
  use Oban.Worker

  import HackScraper.Worker.Common

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"url" => url, "series_id" => series_id}}) do
    Logger.info("Running Luma scraper on #{url}...")

    events = get!(url).body["entries"]
    hackathons = filter_hackathons(events)
    Logger.info("Found #{length(hackathons)}/#{length(events)} hackathons")

    hackathons =
      for entry <- hackathons do
        event = entry["event"]

        %{
          url: URI.merge("https://luma.com", event["url"]) |> to_string(),
          name: event["name"],
          start_date: parse_date(event["start_at"]),
          end_date: parse_date(event["end_at"]),
          series_id: series_id
        }
      end

    hackathons
    |> Enum.with_index()
    |> Enum.reduce(Ecto.Multi.new(), fn {event, index}, multi ->
      job = HackScraper.Worker.Luma.AddInfo.new(%{event: event}, schedule_in: index * 180)

      Oban.insert(multi, "addinfo-#{index}", job)
    end)
    |> HackScraper.Repo.transaction()

    Logger.info("Queued AddInfo jobs")
  end

  defp filter_hackathons(entries) do
    Enum.filter(entries, fn entry ->
      event = entry["event"]
      name = String.downcase(event["name"] || "")
      String.contains?(name, ["hack", "coding", "tech challenge"])
    end)
  end
end

defmodule HackScraper.Worker.Luma.AddInfo do
  use Oban.Worker,
    priority: 3,
    unique: [period: {60, :days}, states: :all, fields: [:queue, :args], keys: [:event]],
    max_attempts: 2

  require Logger
  import HackScraper.Worker.Common

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"event" => event}}) do
    event =
      for({key, val} <- event, into: %{}, do: {String.to_existing_atom(key), val})

    Logger.info("Running Luma AddInfo scraper: #{event.url}...")

    html = get!(event.url).body |> Floki.parse_document!()

    json_ld =
      html
      |> Floki.find("script[type='application/ld+json']")
      |> List.first()
      |> case do
        {"script", _, [json_str]} -> Jason.decode!(json_str)
        _ -> %{}
      end

    description =
      case json_ld["description"] do
        desc when is_binary(desc) ->
          desc
          |> String.split("\n")
          |> Enum.take(5)
          |> Enum.join("\n")
          |> String.trim()

        _ ->
          ""
      end

    location =
      case json_ld["location"] do
        %{"name" => name} when is_binary(name) -> name
        _ -> nil
      end

    image =
      case json_ld["image"] do
        [first | _] when is_binary(first) -> first
        img when is_binary(img) -> img
        _ -> nil
      end

    hackathon =
      event
      |> Map.put(:description, description)
      |> Map.put(:location, location)
      |> Map.put(:image, image)
      |> Map.put(:start_date, parse_date(event[:start_date] || json_ld["startDate"]))
      |> Map.put(:end_date, parse_date(event[:end_date] || json_ld["endDate"]))

    num = upsert_hackathons([hackathon])
    Logger.info("Created/updated #{num} hackathon")
  end
end

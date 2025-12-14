defmodule HackScraper.Worker.Luma do
  use Oban.Worker

  import HackScraper.Worker.Common

  require Logger

  @api_url "https://api2.luma.com/discover/get-paginated-events?latitude=48.13743&longitude=11.57549&pagination_limit=30&slug=tech"

  @impl Oban.Worker
  def perform(%Oban.Job{} = _job) do
    Logger.info("Running Luma scraper...")

    events = get!(@api_url).body["entries"]
    hackathons = filter_hackathons(events)
    Logger.info("Found #{length(hackathons)}/#{length(events)} hackathons")

    hackathons =
      for entry <- hackathons do
        event = entry["event"]

        %{
          url: "https://luma.com/#{event["url"]}",
          name: event["name"],
          start_date: parse_date(event["start_at"]),
          end_date: parse_date(event["end_at"])
        }
      end

    hackathons
    |> Enum.with_index()
    |> Enum.reduce(Ecto.Multi.new(), fn {event, index}, multi ->
      job = HackScraper.Worker.Luma.AddInfo.new(%{event: event}, schedule_in: index * 60)

      Oban.insert(multi, "addinfo-#{index}", job)
    end)
    |> HackScraper.Repo.transaction()

    Logger.info("Queued AddInfo jobs")
  end

  defp filter_hackathons(entries) do
    Enum.filter(entries, fn entry ->
      event = entry["event"]
      name = String.downcase(event["name"] || "")
      String.contains?(name, ["hackathon", "hack ", "coding ", "hackfest", "tech challenge"])
    end)
  end
end

defmodule HackScraper.Worker.Luma.AddInfo do
  use Oban.Worker,
    priority: 3,
    unique: [period: {60, :days}, states: :all, fields: [:queue, :args], keys: [:url]]

  require Logger
  import HackScraper.Worker.Common

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"event" => event}}) do
    event =
      for({key, val} <- event, into: %{}, do: {String.to_existing_atom(key), val})

    event =
      Map.put(event, :start_date, parse_date(event[:start_date]))
      |> Map.put(:end_date, parse_date(event[:end_date]))

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

    num = upsert_hackathons([hackathon])
    Logger.info("Created/updated #{num} hackathon")
  end
end

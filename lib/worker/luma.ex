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
        url = "https://luma.com/#{event["url"]}"

        # TODO schedule extra job to get actual description and easy location from event page
        %{
          url: url,
          image: event["cover_url"],
          name: event["name"],
          description: build_description(event),
          start_date: parse_date(event["start_at"]),
          end_date: parse_date(event["end_at"]),
          location: format_location(event["geo_address_info"])
        }
      end

    num = upsert_hackathons(hackathons)
    Logger.info("Created/updated #{num} hackathons")
  end

  # Filter events that are likely hackathons
  defp filter_hackathons(entries) do
    Enum.filter(entries, fn entry ->
      event = entry["event"]
      name = String.downcase(event["name"] || "")
      String.contains?(name, ["hackathon", "hack ", "coding ", "hackfest", "tech challenge"])
    end)
  end

  defp build_description(event) do
    parts = []

    # Add calendar/organizer info if available
    parts =
      if calendar = event["calendar"] do
        org_name = calendar["name"]

        if org_name && org_name != "Personal" do
          [org_name | parts]
        else
          parts
        end
      else
        parts
      end

    # Add host information
    parts =
      if hosts = event["hosts"] do
        host_names =
          hosts
          |> Enum.map(& &1["name"])
          |> Enum.reject(&is_nil/1)
          |> Enum.take(3)
          |> Enum.join(", ")

        if host_names != "" do
          ["Hosted by: #{host_names}" | parts]
        else
          parts
        end
      else
        parts
      end

    # Add guest count if available
    parts =
      if guest_count = event["guest_count"] do
        if guest_count > 0 do
          ["#{guest_count} participants" | parts]
        else
          parts
        end
      else
        parts
      end

    # Add ticket info
    parts =
      if ticket_info = event["ticket_info"] do
        cond do
          ticket_info["is_free"] ->
            ["Free event" | parts]

          price = ticket_info["price"] ->
            amount = price["cents"] / 100
            currency = String.upcase(price["currency"] || "EUR")
            ["Price: #{amount} #{currency}" | parts]

          true ->
            parts
        end
      else
        parts
      end

    Enum.reverse(parts) |> Enum.join("\\n")
  end

  defp format_location(geo_info) do
    case geo_info do
      %{"mode" => "obfuscated", "city_state" => city_state} ->
        city_state || "Munich, Germany"

      %{"full_address" => address} when is_binary(address) ->
        address

      %{"city" => city, "country" => country} ->
        "#{city}, #{country}"

      %{"city" => city} ->
        city

      _ ->
        "Munich, Germany"
    end
  end
end

defmodule HackScraper.Worker.Unternehmertum do
  use Oban.Worker

  import HackScraper.Worker.Common

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"url" => url}}) do
    Logger.info("Running Unternehmertum scraper...")

    html = get!(url).body
    {:ok, document} = Floki.parse_document(html)

    table_list = Floki.find(document, ".table-list")
    events = Floki.find(table_list, "li")

    Logger.info("Found #{length(events)} hackathons")

    suggestions =
      for event <- events do
        url = event |> Floki.find("a") |> Floki.attribute("href") |> List.first()
        date_hint = event |> Floki.find("div.col-12.lg\\:col-2") |> Floki.text() |> String.trim()
        name = event |> Floki.find("h3") |> Floki.text() |> String.trim()
        description = event |> Floki.find("div.mb-20.sm\\:mb-30") |> Floki.text() |> String.trim()

        %{url: url, name: name, description: description, date_hint: date_hint}
      end

    num = upsert_suggestions(suggestions)
    Logger.info("Created/updated #{num} suggestions")
  end
end

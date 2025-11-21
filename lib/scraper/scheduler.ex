defmodule HackScraper.Scraper.Scheduler do
  use Oban.Worker

  import HackScraper.Scraper.Common, only: [oban_opts: 0]

  require Logger

  # this worker is scheduled @weekly via the cron plugin in config
  @schedule_days_ahead 7 + 1

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Logger.info("Scheduling scrapers for the next #{@schedule_days_ahead} days...")

    scrapers = HackScraper.Worker.list_scrapers_for_scheduling()

    Logger.info("Found #{length(scrapers)} scrapers")

    for scraper <- scrapers do
      Logger.info("Scheduling scraper #{scraper.name}...")
      schedule_jobs_for_period(scraper)
    end

    Logger.info("Scheduling scrapers completed")
  end

  def schedule_jobs_for_period(scraper) do
    case resolve_scraper_module(scraper.name) do
      {:ok, module} ->
        schedule_executions_for_period(scraper, module)

      {:error, reason} ->
        Logger.error("Failed to resolve module for scraper #{scraper.name}: #{reason}")
    end
  end

  @unique [fields: [:meta], keys: [:name], period: :infinity]

  defp schedule_executions_for_period(scraper, module) do
    case Oban.Plugins.Cron.parse(scraper.schedule) do
      {:ok, cron_expression} ->
        now = DateTime.utc_now()
        end_time = DateTime.add(now, @schedule_days_ahead, :day)

        execution_times = get_execution_times(cron_expression, now, end_time, [])

        Logger.info("Found #{length(execution_times)} execution times for #{scraper.name}")

        for scheduled_at <- execution_times do
          %{url: scraper.url}
          |> module.new(
            oban_opts() ++
              [
                scheduled_at: scheduled_at,
                meta: %{name: "#{scraper.name}-#{scheduled_at}"},
                unique: @unique
              ]
          )
          |> Oban.insert()
        end

      {:error, error} ->
        Logger.error(
          "Failed to parse cron expression '#{scraper.schedule}' for scraper #{scraper.name}: #{error}"
        )
    end
  end

  defp get_execution_times(cron_expression, current_time, end_time, acc) do
    case Oban.Cron.Expression.next_at(cron_expression, current_time) do
      :unknown ->
        # For @reboot or other special cases
        acc

      next_time when next_time != nil ->
        if DateTime.compare(next_time, end_time) == :lt do
          get_execution_times(cron_expression, next_time, end_time, [next_time | acc])
        else
          acc
        end
    end
  end

  def schedule_job(scraper) do
    case resolve_scraper_module(scraper.name) do
      {:ok, module} ->
        %{url: scraper.url}
        |> module.new(oban_opts() ++ [schedule_in: 1])
        |> Oban.insert()

      {:error, reason} ->
        Logger.error("Failed to resolve module for scraper #{scraper.name}: #{reason}")
    end
  end

  defp resolve_scraper_module(name) when is_binary(name) do
    # also update scraper validation
    case name |> String.split("-", parts: 2) |> List.first() do
      "devpost" -> {:ok, HackScraper.Scraper.Devpost}
      "direct" -> {:ok, HackScraper.Scraper.Direct}
      "dummy" -> {:ok, HackScraper.Scraper.Dummy}
      _ -> {:error, "Unknown scraper type: #{name}"}
    end
  end
end

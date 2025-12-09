defmodule HackScraper.Worker.Scheduler do
  use Oban.Worker

  import HackScraper.Worker.Common, only: [oban_opts: 0, worker_module: 1]
  alias HackScraper.Scrapers
  alias HackScraper.Scrapers.Scraper

  require Logger

  # this worker is scheduled @weekly via the cron plugin in config
  @schedule_days_ahead 7 + 1

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Logger.info("Scheduling scrapers for the next #{@schedule_days_ahead} days...")

    scrapers = Scrapers.list_scrapers_for_scheduling()

    Logger.info("Found #{length(scrapers)} scrapers")

    for scraper <- scrapers do
      Logger.info("Scheduling scraper #{scraper.id} #{scraper.worker}...")
      schedule_executions_for_period(scraper)
    end

    Logger.info("Scheduling scrapers completed")
  end

  def schedule_job(%Scraper{} = scraper) do
    module = worker_module(scraper.worker)

    %{url: scraper.url}
    |> module.new(oban_opts() ++ [schedule_in: 1, unique: false])
    |> Oban.insert()
  end

  @unique [
    period: :infinity,
    states: :all,
    fields: [:queue, :meta],
    keys: [:scraper_id, :scheduled_at]
  ]

  def schedule_executions_for_period(%Scraper{paused: true} = scraper) do
    Logger.debug("Skipping scheduling for paused scraper #{scraper.id} #{scraper.worker}")
    {:ok, nil}
  end

  def schedule_executions_for_period(%Scraper{} = scraper) do
    case Oban.Plugins.Cron.parse(scraper.schedule) do
      {:ok, cron_expression} ->
        now = DateTime.utc_now()
        end_time = DateTime.add(now, @schedule_days_ahead, :day)

        execution_times = get_execution_times(cron_expression, now, end_time, [])

        Logger.info(
          "Found #{length(execution_times)} execution times for #{scraper.id} #{scraper.worker}"
        )

        module = worker_module(scraper.worker)

        for scheduled_at <- execution_times do
          {:ok, _job} =
            %{url: scraper.url}
            |> module.new(
              oban_opts() ++
                [
                  unique: @unique,
                  scheduled_at: scheduled_at,
                  meta: %{scraper_id: scraper.id, scheduled_at: scheduled_at}
                ]
            )
            |> Oban.insert()
        end

        {:ok, nil}

      {:error, error} ->
        Logger.error(
          "Failed to parse cron expression '#{scraper.schedule}' for #{scraper.id} #{scraper.worker}: #{error}"
        )

        {:error, error}
    end
  end

  def get_execution_times(cron_expression, current_time, end_time, acc) do
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
end

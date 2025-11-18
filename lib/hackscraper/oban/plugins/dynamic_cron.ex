defmodule HackScraper.Oban.Plugins.DynamicCron do
  @moduledoc """
  An Oban plugin that schedules jobs based on dynamic cron expressions stored in the database.

  This plugin periodically checks the database for enabled dynamic cron schedules and
  enqueues jobs based on their cron expressions.

  ## Options

    * `:interval` - The number of milliseconds between schedule checks. Defaults to 60_000 (1 minute).
    * `:timezone` - The timezone to use for cron expressions. Defaults to "Etc/UTC".

  ## Example Configuration

      config :hackscraper, Oban,
        plugins: [
          {HackScraper.Oban.Plugins.DynamicCron, interval: 60_000, timezone: "America/New_York"}
        ]
  """

  @behaviour Oban.Plugin

  use GenServer
  require Logger

  alias HackScraper.Oban.DynamicCron
  alias HackScraper.Oban.DynamicCronSchedule

  @impl Oban.Plugin
  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl GenServer
  def init(opts) do
    interval = Keyword.get(opts, :interval, 60_000)
    timezone = Keyword.get(opts, :timezone, "Etc/UTC")
    oban_name = Keyword.fetch!(opts, :conf)

    state = %{
      interval: interval,
      timezone: timezone,
      oban_name: oban_name,
      timer: schedule_check(interval)
    }

    Logger.info("DynamicCron plugin started with interval: #{interval}ms, timezone: #{timezone}")

    {:ok, state}
  end

  @impl GenServer
  def handle_info(:check_schedules, state) do
    check_and_enqueue_jobs(state)
    {:noreply, %{state | timer: schedule_check(state.interval)}}
  end

  @impl Oban.Plugin
  def validate(opts) do
    Keyword.validate(opts, [:conf, :name, interval: 60_000, timezone: "Etc/UTC"])
  end

  defp schedule_check(interval) do
    Process.send_after(self(), :check_schedules, interval)
  end

  defp check_and_enqueue_jobs(state) do
    schedules = DynamicCron.list_enabled_schedules()
    now = DateTime.now!(state.timezone)

    Enum.each(schedules, fn schedule ->
      if should_execute?(schedule, now, state.timezone) do
        enqueue_job(schedule, state.oban_name)
      end
    end)
  end

  defp should_execute?(schedule, now, timezone) do
    case Crontab.CronExpression.Parser.parse(schedule.cron_expression) do
      {:ok, cron_expression} ->
        # Get the last execution time or use a time far in the past
        last_executed =
          schedule.last_executed_at ||
            DateTime.add(now, -1, :day)

        # Check if the job should run between last execution and now
        case Crontab.Scheduler.get_next_run_date(cron_expression, DateTime.to_naive(last_executed)) do
          {:ok, next_run} ->
            next_run_datetime = DateTime.from_naive!(next_run, timezone)
            DateTime.compare(next_run_datetime, now) in [:lt, :eq]

          {:error, _} ->
            false
        end

      {:error, reason} ->
        Logger.error("Invalid cron expression for schedule #{schedule.name}: #{inspect(reason)}")
        false
    end
  end

  defp enqueue_job(%DynamicCronSchedule{} = schedule, oban_name) do
    worker_module = String.to_existing_atom("Elixir.#{schedule.worker}")

    case Oban.insert(oban_name, worker_module.new(schedule.args)) do
      {:ok, job} ->
        Logger.info("Enqueued job for schedule: #{schedule.name}, job_id: #{job.id}")
        DynamicCron.update_last_executed_at(schedule)

      {:error, reason} ->
        Logger.error("Failed to enqueue job for schedule #{schedule.name}: #{inspect(reason)}")
    end
  rescue
    error ->
      Logger.error("Error enqueuing job for schedule #{schedule.name}: #{inspect(error)}")
  end
end

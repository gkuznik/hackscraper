defmodule HackScraper.ObanTelemetryHandler do
  require Logger

  def handle_event([:oban, :job, :exception], _measurements, metadata, _config) do
    %{
      job: job,
      attempt: attempt,
      max_attempts: max_attempts,
      error: error,
      stacktrace: stacktrace
    } = metadata

    if (job.queue == "scraper" or job.queue == :scraper) and attempt >= max_attempts do
      Logger.error(
        "Scraper #{job.worker} failed after #{attempt} attempts. Queuing alert email..."
      )

      error_msg = inspect(error)
      stack_msg = Exception.format_stacktrace(stacktrace)
      job_args = job.args || %{}

      # Enqueue the email notification job using Oban
      %{
        "worker" => job.worker,
        "args" => job_args,
        "error" => error_msg,
        "stacktrace" => stack_msg
      }
      |> HackScraper.Worker.ScraperNotifier.new()
      |> Oban.insert()
    end
  rescue
    e ->
      Logger.error("Error in HackScraper.ObanTelemetryHandler: #{inspect(e)}")
      :ok
  end
end

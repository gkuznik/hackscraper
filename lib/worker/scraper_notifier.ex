defmodule HackScraper.Worker.ScraperNotifier do
  use Oban.Worker, queue: :emails, max_attempts: 3

  import Swoosh.Email
  alias HackScraper.Mailer

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    %{"worker" => worker, "args" => job_args, "error" => error, "stacktrace" => stacktrace} = args

    recipient = Application.get_env(:hackscraper, :contact_mail)
    sender = Application.get_env(:hackscraper, :sender_mail)

    Logger.info("Sending scraper failure notification email for #{worker} to #{recipient}...")

    email =
      new()
      |> to(recipient)
      |> from({"HackScraper Admin", sender})
      |> subject("🚨 Scraper Job Failed: #{worker}")
      |> text_body("""
      A scraper job has exhausted all retries and failed.

      Worker: #{worker}

      Job Arguments:
      #{inspect(job_args, pretty: true)}

      Error Details:
      #{error}

      Stacktrace:
      #{stacktrace}
      """)

    case Mailer.deliver(email) do
      {:ok, _metadata} ->
        Logger.info("Scraper failure notification email sent successfully.")
        :ok

      {:error, reason} ->
        Logger.error("Failed to send scraper failure notification email: #{inspect(reason)}")
        {:error, reason}
    end
  end
end

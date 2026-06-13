defmodule HackScraper.Worker.ScraperNotifierTest do
  use HackScraper.DataCase, async: true
  use Oban.Testing, repo: HackScraper.Repo

  import Swoosh.TestAssertions

  alias HackScraper.Worker.ScraperNotifier
  alias HackScraper.ObanTelemetryHandler

  describe "perform/1" do
    test "sends failure email successfully" do
      args = %{
        "worker" => "HackScraper.Worker.Devpost",
        "args" => %{"url" => "https://example.com/failed"},
        "error" => "RuntimeError: connection timeout",
        "stacktrace" => "lib/worker/devpost.ex:12"
      }

      assert :ok = ScraperNotifier.perform(%Oban.Job{args: args})

      assert_email_sent(
        subject: "🚨 Scraper Job Failed: HackScraper.Worker.Devpost",
        to: Application.get_env(:hackscraper, :contact_mail)
      )
    end
  end

  describe "telemetry handler" do
    @tag :capture_log
    test "enqueues a ScraperNotifier job when a scraper job exhausts its retries" do
      # Create a simulated Oban job for a scraper queue
      job = %Oban.Job{
        id: 123,
        queue: "scraper",
        worker: "HackScraper.Worker.Devpost",
        args: %{"url" => "https://example.com/failed"},
        attempt: 3,
        max_attempts: 3
      }

      metadata = %{
        job: job,
        attempt: 3,
        max_attempts: 3,
        error: %RuntimeError{message: "connection timeout"},
        stacktrace: []
      }

      # Call the telemetry handler directly
      ObanTelemetryHandler.handle_event(
        [:oban, :job, :exception],
        %{duration: 1200},
        metadata,
        nil
      )

      # Verify that a ScraperNotifier job has been enqueued
      assert_enqueued(
        worker: ScraperNotifier,
        args: %{
          "worker" => "HackScraper.Worker.Devpost",
          "args" => %{"url" => "https://example.com/failed"},
          "error" => "%RuntimeError{message: \"connection timeout\"}",
          "stacktrace" => "\n"
        }
      )
    end

    test "does not enqueue a job when a scraper job fails but has remaining retries" do
      job = %Oban.Job{
        id: 124,
        queue: "scraper",
        worker: "HackScraper.Worker.Devpost",
        args: %{"url" => "https://example.com/failed"},
        attempt: 1,
        max_attempts: 3
      }

      metadata = %{
        job: job,
        attempt: 1,
        max_attempts: 3,
        error: %RuntimeError{message: "connection timeout"},
        stacktrace: []
      }

      # Call the telemetry handler directly
      ObanTelemetryHandler.handle_event(
        [:oban, :job, :exception],
        %{duration: 1200},
        metadata,
        nil
      )

      # Verify that NO ScraperNotifier job is enqueued
      refute_enqueued(worker: ScraperNotifier)
    end

    test "does not enqueue a job when a non-scraper job fails and exhausts retries" do
      job = %Oban.Job{
        id: 125,
        queue: "emails",
        worker: "HackScraper.Accounts.UserNotifier",
        args: %{"url" => "https://example.com/failed"},
        attempt: 3,
        max_attempts: 3
      }

      metadata = %{
        job: job,
        attempt: 3,
        max_attempts: 3,
        error: %RuntimeError{message: "smtp timeout"},
        stacktrace: []
      }

      # Call the telemetry handler directly
      ObanTelemetryHandler.handle_event(
        [:oban, :job, :exception],
        %{duration: 1200},
        metadata,
        nil
      )

      # Verify that NO ScraperNotifier job is enqueued
      refute_enqueued(worker: ScraperNotifier)
    end
  end
end

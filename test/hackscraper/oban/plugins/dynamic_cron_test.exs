defmodule HackScraper.Oban.Plugins.DynamicCronTest do
  use HackScraper.DataCase, async: false

  alias HackScraper.Oban.DynamicCron
  alias HackScraper.Oban.Plugins.DynamicCron, as: DynamicCronPlugin

  setup do
    # Start Oban for testing
    start_supervised!({Oban, testing: :manual, queues: false, repo: HackScraper.Repo})
    :ok
  end

  describe "plugin initialization" do
    test "plugin validates required options" do
      assert {:ok, _} =
               DynamicCronPlugin.validate(
                 conf: Oban.config(),
                 name: DynamicCronPlugin,
                 interval: 60_000,
                 timezone: "Etc/UTC"
               )
    end

    test "plugin uses default values for optional options" do
      assert {:ok, validated} =
               DynamicCronPlugin.validate(conf: Oban.config(), name: DynamicCronPlugin)

      assert Keyword.get(validated, :interval) == 60_000
      assert Keyword.get(validated, :timezone) == "Etc/UTC"
    end
  end

  describe "schedule checking" do
    test "enqueues job for schedule that should run" do
      # Create a schedule that should run (cron expression that matches current time)
      {:ok, _schedule} =
        DynamicCron.create_schedule(%{
          name: "test_immediate",
          cron_expression: "* * * * *",
          # every minute
          worker: "HackScraper.Scraper.Devpost",
          args: %{},
          enabled: true
        })

      # Start the plugin
      {:ok, pid} =
        start_supervised(
          {DynamicCronPlugin,
           conf: Oban.config(), name: DynamicCronPluginTest, interval: 100}
        )

      # Give the plugin time to check schedules
      Process.sleep(200)

      # Check that a job was enqueued
      jobs = Oban.Job |> HackScraper.Repo.all()
      assert length(jobs) > 0

      # Clean up
      stop_supervised(pid)
    end

    test "does not enqueue job for disabled schedule" do
      # Create a disabled schedule
      {:ok, _schedule} =
        DynamicCron.create_schedule(%{
          name: "test_disabled",
          cron_expression: "* * * * *",
          worker: "HackScraper.Scraper.Devpost",
          args: %{},
          enabled: false
        })

      # Start the plugin
      {:ok, pid} =
        start_supervised(
          {DynamicCronPlugin,
           conf: Oban.config(), name: DynamicCronPluginTest2, interval: 100}
        )

      # Give the plugin time to check schedules
      Process.sleep(200)

      # Check that no jobs were enqueued
      jobs = Oban.Job |> HackScraper.Repo.all()
      assert length(jobs) == 0

      # Clean up
      stop_supervised(pid)
    end

    test "updates last_executed_at after enqueuing job" do
      # Create a schedule
      {:ok, schedule} =
        DynamicCron.create_schedule(%{
          name: "test_last_executed",
          cron_expression: "* * * * *",
          worker: "HackScraper.Scraper.Devpost",
          args: %{},
          enabled: true
        })

      assert schedule.last_executed_at == nil

      # Start the plugin
      {:ok, pid} =
        start_supervised(
          {DynamicCronPlugin,
           conf: Oban.config(), name: DynamicCronPluginTest3, interval: 100}
        )

      # Give the plugin time to check schedules
      Process.sleep(200)

      # Check that last_executed_at was updated
      updated_schedule = DynamicCron.get_schedule!(schedule.id)
      assert updated_schedule.last_executed_at != nil

      # Clean up
      stop_supervised(pid)
    end
  end

  describe "cron expression handling" do
    test "handles various cron expressions" do
      # Test that various cron expressions are accepted
      expressions = [
        "@yearly",
        "@annually",
        "@monthly",
        "@weekly",
        "@daily",
        "@midnight",
        "@hourly",
        "0 0 * * *",
        "*/5 * * * *",
        "0 0,12 * * *"
      ]

      Enum.each(expressions, fn expr ->
        attrs = %{
          name: "test_#{String.replace(expr, ~r/[^a-zA-Z0-9]/, "_")}",
          cron_expression: expr,
          worker: "HackScraper.Scraper.Devpost",
          args: %{},
          enabled: true
        }

        assert {:ok, _schedule} = DynamicCron.create_schedule(attrs)
      end)
    end
  end
end

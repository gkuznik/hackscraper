defmodule HackScraper.Worker.SchedulerTest do
  use ExUnit.Case, async: true

  alias HackScraper.Worker.Scheduler

  describe "get_execution_times/4" do
    test "returns list of execution times for hourly cron" do
      {:ok, cron_expression} = Oban.Plugins.Cron.parse("0 * * * *")
      now = ~U[2025-12-08 10:30:00Z]
      end_time = ~U[2025-12-08 14:00:00Z]

      execution_times = Scheduler.get_execution_times(cron_expression, now, end_time, [])

      expected = [
        ~U[2025-12-08 13:00:00Z],
        ~U[2025-12-08 12:00:00Z],
        ~U[2025-12-08 11:00:00Z]
      ]

      assert execution_times == expected
    end

    test "returns empty list when no executions fall within the period" do
      {:ok, cron_expression} = Oban.Plugins.Cron.parse("0 0 * * *")
      now = ~U[2025-12-08 10:00:00Z]
      end_time = ~U[2025-12-08 12:00:00Z]

      execution_times = Scheduler.get_execution_times(cron_expression, now, end_time, [])

      # No midnight between 10:00 and 12:00 same day
      assert execution_times == []
    end

    test "returns empty list for @reboot special case" do
      {:ok, cron_expression} = Oban.Plugins.Cron.parse("@reboot")
      now = ~U[2025-12-08 10:00:00Z]
      end_time = ~U[2025-12-09 10:00:00Z]

      execution_times = Scheduler.get_execution_times(cron_expression, now, end_time, [])

      assert execution_times == []
    end
  end
end

defmodule HackScraper.Oban.DynamicCronExample do
  @moduledoc """
  Example usage of the Dynamic Cron Plugin.

  This module demonstrates how to create and manage dynamic cron schedules.
  """

  alias HackScraper.Oban.DynamicCron

  @doc """
  Creates example dynamic cron schedules.

  ## Example

      iex> HackScraper.Oban.DynamicCronExample.create_examples()
      :ok
  """
  def create_examples do
    # Example 1: Daily scraper job
    {:ok, _} =
      DynamicCron.create_schedule(%{
        name: "daily_devpost_scraper",
        cron_expression: "@daily",
        worker: "HackScraper.Scraper.Devpost",
        args: %{},
        enabled: true
      })

    # Example 2: Hourly job with custom args
    {:ok, _} =
      DynamicCron.create_schedule(%{
        name: "hourly_custom_scraper",
        cron_expression: "@hourly",
        worker: "HackScraper.Scraper.Devpost",
        args: %{"custom_param" => "value"},
        enabled: true
      })

    # Example 3: Every 5 minutes (initially disabled)
    {:ok, _} =
      DynamicCron.create_schedule(%{
        name: "frequent_scraper",
        cron_expression: "*/5 * * * *",
        worker: "HackScraper.Scraper.Devpost",
        args: %{},
        enabled: false
      })

    # Example 4: Weekly on Monday at 9 AM
    {:ok, _} =
      DynamicCron.create_schedule(%{
        name: "weekly_monday_scraper",
        cron_expression: "0 9 * * 1",
        worker: "HackScraper.Scraper.Devpost",
        args: %{},
        enabled: true
      })

    :ok
  end

  @doc """
  Lists all current dynamic cron schedules.

  ## Example

      iex> HackScraper.Oban.DynamicCronExample.list_all()
      # Returns list of all schedules
  """
  def list_all do
    DynamicCron.list_schedules()
    |> Enum.map(fn schedule ->
      %{
        name: schedule.name,
        cron: schedule.cron_expression,
        worker: schedule.worker,
        enabled: schedule.enabled,
        last_run: schedule.last_executed_at
      }
    end)
  end

  @doc """
  Enables a schedule by name.

  ## Example

      iex> HackScraper.Oban.DynamicCronExample.enable("frequent_scraper")
      {:ok, %DynamicCronSchedule{}}
  """
  def enable(schedule_name) do
    case DynamicCron.get_schedule_by_name(schedule_name) do
      nil -> {:error, :not_found}
      schedule -> DynamicCron.enable_schedule(schedule)
    end
  end

  @doc """
  Disables a schedule by name.

  ## Example

      iex> HackScraper.Oban.DynamicCronExample.disable("frequent_scraper")
      {:ok, %DynamicCronSchedule{}}
  """
  def disable(schedule_name) do
    case DynamicCron.get_schedule_by_name(schedule_name) do
      nil -> {:error, :not_found}
      schedule -> DynamicCron.disable_schedule(schedule)
    end
  end

  @doc """
  Updates a schedule's cron expression.

  ## Example

      iex> HackScraper.Oban.DynamicCronExample.update_cron("daily_devpost_scraper", "@weekly")
      {:ok, %DynamicCronSchedule{}}
  """
  def update_cron(schedule_name, new_cron_expression) do
    case DynamicCron.get_schedule_by_name(schedule_name) do
      nil ->
        {:error, :not_found}

      schedule ->
        DynamicCron.update_schedule(schedule, %{cron_expression: new_cron_expression})
    end
  end

  @doc """
  Deletes all example schedules.

  ## Example

      iex> HackScraper.Oban.DynamicCronExample.cleanup()
      :ok
  """
  def cleanup do
    example_names = [
      "daily_devpost_scraper",
      "hourly_custom_scraper",
      "frequent_scraper",
      "weekly_monday_scraper"
    ]

    Enum.each(example_names, fn name ->
      case DynamicCron.get_schedule_by_name(name) do
        nil -> :ok
        schedule -> DynamicCron.delete_schedule(schedule)
      end
    end)

    :ok
  end
end

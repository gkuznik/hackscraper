defmodule HackScraper.Oban.DynamicCron do
  @moduledoc """
  Context for managing dynamic cron schedules.
  """
  import Ecto.Query, warn: false
  alias HackScraper.Repo
  alias HackScraper.Oban.DynamicCronSchedule

  @doc """
  Returns the list of enabled dynamic cron schedules.
  """
  def list_enabled_schedules do
    Repo.all(from s in DynamicCronSchedule, where: s.enabled == true)
  end

  @doc """
  Returns the list of all dynamic cron schedules.
  """
  def list_schedules do
    Repo.all(DynamicCronSchedule)
  end

  @doc """
  Gets a single schedule by name.
  """
  def get_schedule_by_name(name) do
    Repo.get_by(DynamicCronSchedule, name: name)
  end

  @doc """
  Gets a single schedule by id.
  """
  def get_schedule!(id) do
    Repo.get!(DynamicCronSchedule, id)
  end

  @doc """
  Creates a schedule.
  """
  def create_schedule(attrs \\ %{}) do
    %DynamicCronSchedule{}
    |> DynamicCronSchedule.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a schedule.
  """
  def update_schedule(%DynamicCronSchedule{} = schedule, attrs) do
    schedule
    |> DynamicCronSchedule.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a schedule.
  """
  def delete_schedule(%DynamicCronSchedule{} = schedule) do
    Repo.delete(schedule)
  end

  @doc """
  Updates the last_executed_at timestamp for a schedule.
  """
  def update_last_executed_at(%DynamicCronSchedule{} = schedule) do
    schedule
    |> Ecto.Changeset.change(last_executed_at: DateTime.utc_now())
    |> Repo.update()
  end

  @doc """
  Enables a schedule.
  """
  def enable_schedule(%DynamicCronSchedule{} = schedule) do
    update_schedule(schedule, %{enabled: true})
  end

  @doc """
  Disables a schedule.
  """
  def disable_schedule(%DynamicCronSchedule{} = schedule) do
    update_schedule(schedule, %{enabled: false})
  end
end

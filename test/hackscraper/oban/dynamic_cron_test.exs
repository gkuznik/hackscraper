defmodule HackScraper.Oban.DynamicCronTest do
  use HackScraper.DataCase

  alias HackScraper.Oban.DynamicCron
  alias HackScraper.Oban.DynamicCronSchedule

  describe "list_schedules/0" do
    test "returns all schedules" do
      schedule = create_schedule()
      assert [^schedule] = DynamicCron.list_schedules()
    end

    test "returns empty list when no schedules exist" do
      assert [] = DynamicCron.list_schedules()
    end
  end

  describe "list_enabled_schedules/0" do
    test "returns only enabled schedules" do
      enabled_schedule = create_schedule(%{enabled: true})
      _disabled_schedule = create_schedule(%{name: "disabled", enabled: false})

      schedules = DynamicCron.list_enabled_schedules()
      assert length(schedules) == 1
      assert hd(schedules).id == enabled_schedule.id
    end
  end

  describe "get_schedule_by_name/1" do
    test "returns schedule when it exists" do
      schedule = create_schedule()
      assert %DynamicCronSchedule{} = found = DynamicCron.get_schedule_by_name(schedule.name)
      assert found.id == schedule.id
    end

    test "returns nil when schedule does not exist" do
      assert nil == DynamicCron.get_schedule_by_name("nonexistent")
    end
  end

  describe "get_schedule!/1" do
    test "returns schedule when it exists" do
      schedule = create_schedule()
      assert %DynamicCronSchedule{} = found = DynamicCron.get_schedule!(schedule.id)
      assert found.id == schedule.id
    end

    test "raises when schedule does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        DynamicCron.get_schedule!(999_999)
      end
    end
  end

  describe "create_schedule/1" do
    test "creates schedule with valid attributes" do
      attrs = %{
        name: "test_schedule",
        cron_expression: "@daily",
        worker: "HackScraper.Scraper.Devpost",
        args: %{"key" => "value"}
      }

      assert {:ok, %DynamicCronSchedule{} = schedule} = DynamicCron.create_schedule(attrs)
      assert schedule.name == "test_schedule"
      assert schedule.cron_expression == "@daily"
      assert schedule.worker == "HackScraper.Scraper.Devpost"
      assert schedule.args == %{"key" => "value"}
      assert schedule.enabled == true
    end

    test "returns error with invalid cron expression" do
      attrs = %{
        name: "test_schedule",
        cron_expression: "invalid",
        worker: "HackScraper.Scraper.Devpost"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = DynamicCron.create_schedule(attrs)
      assert "invalid cron expression" in errors_on(changeset).cron_expression
    end

    test "returns error with non-existent worker" do
      attrs = %{
        name: "test_schedule",
        cron_expression: "@daily",
        worker: "NonExistent.Worker"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = DynamicCron.create_schedule(attrs)
      assert "worker module does not exist" in errors_on(changeset).worker
    end

    test "returns error with duplicate name" do
      create_schedule()

      attrs = %{
        name: "test_schedule",
        cron_expression: "@daily",
        worker: "HackScraper.Scraper.Devpost"
      }

      assert {:error, %Ecto.Changeset{}} = DynamicCron.create_schedule(attrs)
    end
  end

  describe "update_schedule/2" do
    test "updates schedule with valid attributes" do
      schedule = create_schedule()

      attrs = %{
        cron_expression: "@weekly",
        args: %{"updated" => "value"}
      }

      assert {:ok, %DynamicCronSchedule{} = updated} =
               DynamicCron.update_schedule(schedule, attrs)

      assert updated.cron_expression == "@weekly"
      assert updated.args == %{"updated" => "value"}
    end

    test "returns error with invalid cron expression" do
      schedule = create_schedule()

      attrs = %{cron_expression: "invalid"}

      assert {:error, %Ecto.Changeset{} = changeset} =
               DynamicCron.update_schedule(schedule, attrs)

      assert "invalid cron expression" in errors_on(changeset).cron_expression
    end
  end

  describe "delete_schedule/1" do
    test "deletes the schedule" do
      schedule = create_schedule()
      assert {:ok, %DynamicCronSchedule{}} = DynamicCron.delete_schedule(schedule)
      assert nil == DynamicCron.get_schedule_by_name(schedule.name)
    end
  end

  describe "update_last_executed_at/1" do
    test "updates the last_executed_at timestamp" do
      schedule = create_schedule()
      assert schedule.last_executed_at == nil

      assert {:ok, %DynamicCronSchedule{} = updated} =
               DynamicCron.update_last_executed_at(schedule)

      assert updated.last_executed_at != nil
      assert DateTime.compare(updated.last_executed_at, DateTime.utc_now()) in [:lt, :eq]
    end
  end

  describe "enable_schedule/1" do
    test "enables a disabled schedule" do
      schedule = create_schedule(%{enabled: false})
      assert {:ok, %DynamicCronSchedule{} = updated} = DynamicCron.enable_schedule(schedule)
      assert updated.enabled == true
    end
  end

  describe "disable_schedule/1" do
    test "disables an enabled schedule" do
      schedule = create_schedule(%{enabled: true})
      assert {:ok, %DynamicCronSchedule{} = updated} = DynamicCron.disable_schedule(schedule)
      assert updated.enabled == false
    end
  end

  # Helper function to create a schedule
  defp create_schedule(attrs \\ %{}) do
    default_attrs = %{
      name: "test_schedule",
      cron_expression: "@daily",
      worker: "HackScraper.Scraper.Devpost",
      args: %{},
      enabled: true
    }

    merged_attrs = Map.merge(default_attrs, attrs)

    {:ok, schedule} = DynamicCron.create_schedule(merged_attrs)
    schedule
  end
end

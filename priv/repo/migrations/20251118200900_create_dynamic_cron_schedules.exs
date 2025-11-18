defmodule HackScraper.Repo.Migrations.CreateDynamicCronSchedules do
  use Ecto.Migration

  def change do
    create table(:dynamic_cron_schedules) do
      add :name, :string, null: false
      add :cron_expression, :string, null: false
      add :worker, :string, null: false
      add :args, :map, default: %{}, null: false
      add :enabled, :boolean, default: true, null: false
      add :last_executed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:dynamic_cron_schedules, [:name])
  end
end

defmodule HackScraper.Repo.Migrations.CreateScrapers do
  use Ecto.Migration

  def change do
    create table(:scrapers) do
      add :name, :string
      add :schedule, :string
      add :url, :string
      add :paused, :boolean, default: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:scrapers, :name)
  end
end

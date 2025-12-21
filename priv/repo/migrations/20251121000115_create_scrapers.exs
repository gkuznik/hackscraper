defmodule HackScraper.Repo.Migrations.CreateScrapers do
  use Ecto.Migration

  def change do
    create table(:scrapers) do
      add :name, :string
      add :worker, :string
      add :schedule, :string
      add :url, :text
      add :paused, :boolean, default: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:scrapers, [:name])
    create unique_index(:scrapers, [:url])
  end
end

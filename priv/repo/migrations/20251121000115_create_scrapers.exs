defmodule HackScraper.Repo.Migrations.CreateScrapers do
  use Ecto.Migration

  def change do
    create table(:scrapers) do
      add :worker, :string
      add :schedule, :string
      add :url, :string
      add :paused, :boolean, default: false

      timestamps(type: :utc_datetime)
    end
  end
end

defmodule HackScraper.Repo.Migrations.AddSeriesToScrapers do
  use Ecto.Migration

  def change do
    alter table(:scrapers) do
      add :series_id, references(:series, on_delete: :nilify_all)
    end
  end
end
